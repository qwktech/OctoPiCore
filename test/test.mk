TEST_QCOW_LINK=https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/41.20250302.3.2/x86_64/fedora-coreos-41.20250302.3.2-qemu.x86_64.qcow2.xz
TEST_QCOW=${PWD}/test/octopicore-test.qcow2.xz

test-build-image:
	podman run --rm -it \
	  --pull=always \
	  -v ${PWD}/build/octopicore.ign:/data/octopicore.ign:ro \
	  -v ${PWD}/test:/data/test:z \
	  quay.io/coreos/coreos-installer:release \
	  download \
	    -s ${STREAM} \
	    -p qemu \
	    -f qcow2.xz \
	    --decompress \
	    -C /data/test

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
