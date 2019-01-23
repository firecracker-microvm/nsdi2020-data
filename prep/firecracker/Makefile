# Quick hacky makefile to build firecracker with docker
FC_COMMIT := v0.14.0

.PHONY: build
build: ../../bin/jailer ../../bin/firecracker

../../bin/jailer: firecracker/build/release/jailer
	mkdir -p $(@D)
	cp $< $(@D)

../../bin/firecracker: firecracker/build/release/firecracker
	mkdir -p $(@D)
	cp $< $(@D)

firecracker/build/release/jailer: firecracker/build/release/firecracker
firecracker/build/release/firecracker: firecracker
	cd $< && git checkout $(FC_COMMIT)
	cd $< && git am ../patches/*
	cd $< && tools/devtool -y build --release

firecracker:
	git clone https://github.com/firecracker-microvm/firecracker.git

clean:
	rm -rf firecracker
