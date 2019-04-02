# Quick hack Makefile to compile a minimal static version of qemu

../../bin/qemu-system-x86_64: Dockerfile
	mkdir -p $(@D)
	docker build -t nemu-static .
	mkdir -p out
	docker run --rm -v $(CURDIR)/out:/out nemu-static
	cp -r out/* $(@D) 
