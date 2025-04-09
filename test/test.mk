TEST_QCOW_LINK=https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/41.20250302.3.2/x86_64/fedora-coreos-41.20250302.3.2-qemu.x86_64.qcow2.xz
TEST_QCOW=${PWD}/test/octopicore-test.qcow2.xz

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

test-clean:
	${VIRSH} destroy octopicore-test
	${VIRSH} undefine --remove-all-storage octopicore-test

test:
	${QEMU} -machine raspi4b ${TEST_QCOW}
