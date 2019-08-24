# Quick hacky makefile to build firecracker with docker
FC_COMMIT := v0.17.0

.PHONY: build
build: ../../bin/jailer ../../bin/firecracker

../../bin/jailer: firecracker/build/release-musl/jailer
	mkdir -p $(@D)
	cp $< $(@D)

../../bin/firecracker: firecracker/build/release-musl/firecracker
	mkdir -p $(@D)
	cp $< $(@D)

firecracker/build/release-musl/jailer: firecracker/build/release-musl/firecracker
firecracker/build/release-musl/firecracker: firecracker
	cd $< && git checkout $(FC_COMMIT)
	cd $< && git am ../patches/*
	cd $< && tools/devtool -y build --release

firecracker:
	git clone https://github.com/firecracker-microvm/firecracker.git

clean:
	rm -rf firecracker
