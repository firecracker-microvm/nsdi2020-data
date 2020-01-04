# Quick hacky makefile to build firecracker with docker
FC_COMMIT := v0.20.0

REL_DIR=firecracker/build/cargo_target/x86_64-unknown-linux-musl/release

.PHONY: build
build: ../../bin/jailer ../../bin/firecracker

../../bin/jailer: $(REL_DIR)/jailer
	mkdir -p $(@D)
	cp $< $(@D)

../../bin/firecracker: $(REL_DIR)/firecracker
	mkdir -p $(@D)
	cp $< $(@D)

$(REL_DIR)/jailer: $(REL_DIR)/firecracker
$(REL_DIR)/firecracker: firecracker
	cd $< && git checkout $(FC_COMMIT)
	cd $< && git am ../patches/*
	cd $< && tools/devtool -y build --release

firecracker:
	git clone https://github.com/firecracker-microvm/firecracker.git

clean:
	rm -rf firecracker
