DISK=/dev/sdb

STREAM=stable
TEMP=/tmp/Rpi4boot

SSH_PASSPHRASE=HelloWorld1!

TEST_QCOW_LINK=https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/41.20250302.3.2/x86_64/fedora-coreos-41.20250302.3.2-qemu.x86_64.qcow2.xz
TEST_QCOW=${PWD}/test/octopicore-test.qcow2.xz

.PHONY: build clean install test

build:
ifeq (,$(wildcard ./keys/octopicore-key.pub))	
	ssh-keygen -N ${SSH_PASSPHRASE} -t ed25519 -f ${PWD}/keys/octopicore-key
endif
	podman run --rm -it \
	  --security-opt label=disable \
	  -v ${PWD}/build:${TEMP}:Z \
	  -v ${PWD}:/data:Z \
	  quay.io/fedora/fedora:41 \
	  /data/bin/FCOS41_U-Boot.sh

clean:
	rm -rf build/* keys/*
	podman image rm quay.io/fedora/fedora:41 quay.io/coreos/coreos-installer:release

clean-test:
	virsh destroy octopicore-test
	virsh undefine --remove-all-storage octopicore-test

install:
	sudo podman run --rm -it \
	  --pull=always \
	  --privileged \
	  -v /dev:/dev \
	  -v /run/udev:/run/udev \
	  -v ${PWD}/build/octopicore.ign:/data/octopicore.ign:ro \
	  quay.io/coreos/coreos-installer:release \
	  install ${DISK} \
	    -a aarch64 \
	    -s ${STREAM} \
	    -i /data/octopicore.ign \
	    --append-karg nomodeset
	sudo ${PWD}/bin/install-bootloader.sh ${DISK}

test:
ifeq (,$(wildcard ${TEST_QCOW}))
	wget ${TEST_QCOW_LINK} -o ${TEST_QCOW}
endif
ifneq (active,$(shell sudo virsh net-list | column -t -o '#' | grep default | cut -d '#' -f 2))
	sudo virsh net-start default
endif
	sudo virt-install \
	  --import \
	  --name=octopicore-test \
	  --vcpus=2 \
	  --ram=4096 \
	  --os-variant=fedora-coreos-stable \
	  --network=default \
	  --graphics=none \
	  --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${PWD}/build/octopicore.ign" \
	  --disk="size=20,backing_store=${TEST_QCOW}"
