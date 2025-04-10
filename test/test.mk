TEST_QCOW_LINK=https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/41.20250302.3.2/x86_64/fedora-coreos-41.20250302.3.2-qemu.x86_64.qcow2.xz
TEST_QCOW=${PWD}/test/octopicore-test.qcow2
NBD_DEVICE=/dev/nbd0

test-build-image:
	${CE} run --rm -it \
	  --pull=always \
	  -v ${PWD}/build/octopicore.ign:/data/octopicore.ign:ro \
	  -v ${PWD}/test:/data/test:z \
	  quay.io/coreos/coreos-installer:release \
	  download \
	    -s ${STREAM} \
	    -p qemu \
	    -a aarch64 \
	    -f qcow2.xz \
	    --decompress \
	    -C /data/test
	mv test/fedora-coreos-*-qemu.aarch64.qcow2 ${TEST_QCOW}
	${QEMU_IMG} resize ${TEST_QCOW} 16G
	chcon --verbose --type svirt_home_t ${PWD}/build/octopicore.ign
	sudo ${QEMU_NBD} --connect=${NBD_DEVICE} ${TEST_QCOW}
	sudo ${PWD}/bin/install-bootloader.sh ${NBD_DEVICE}
	sudo ${QEMU_NBD} --disconnect ${NBD_DEVICE}

test-clean:
	rm test/octopicore-test.qcow2

test:
	${QEMU} -machine raspi4b ${TEST_QCOW}
