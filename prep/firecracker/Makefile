# Quick hacky makefile to build firecracker with docker
FC_TAG := v0.14.0
../../bin/firecracker: firecracker/build/release/firecracker
	mkdir -p $(@D)
	cp $< $(@D)
	cp firecracker/build/release/jailer $(@D)

firecracker/build/release/firecracker: firecracker
	cd $< && git checkout $(FC_TAG)
	cd $< && tools/devtool -y build --release

firecracker:
	git clone https://github.com/firecracker-microvm/firecracker.git

clean:
	rm -rf firecracker
