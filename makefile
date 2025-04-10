DISK=/dev/sdb

STREAM=stable
TEMP=/tmp/Rpi4boot

SSH_PASSPHRASE=HelloWorld1!

#CE=podman
CE=flatpak-spawn --host podman
VIRSH=flatpak-spawn --host virsh
QEMU=flatpak-spawn --host qemu-system-aarch64
QEMU_IMG=flatpak-spawn --host qemu-img
QEMU_NBD=flatpak-spawn --host qemu-nbd
MODPROBE=flatpak-spawn --host modprobe
RMMOD=flatpak-spawn --host rmmod

include test/test.mk

.PHONY: build clean install test

build:
ifeq (,$(wildcard ./keys/octopicore-key.pub))	
	ssh-keygen -N ${SSH_PASSPHRASE} -t ed25519 -f ${PWD}/keys/octopicore-key
endif
	${CE} run --rm -it \
	  --security-opt label=disable \
	  -v ${PWD}/build:${TEMP}:Z \
	  -v ${PWD}:/data:Z \
	  quay.io/fedora/fedora:41 \
	  /data/bin/FCOS41_U-Boot.sh

clean:
	rm -rf build/* keys/*
	${CE} image rm quay.io/fedora/fedora:41 quay.io/coreos/coreos-installer:release

install:
	sudo ${CE} run --rm -it \
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

