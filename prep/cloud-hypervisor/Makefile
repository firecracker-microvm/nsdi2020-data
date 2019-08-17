../../bin/cloud-hypervisor: Dockerfile
	mkdir -p $(@D)
	docker build -t cloudhv .
	mkdir -p out
	docker run --rm -v $(CURDIR)/out:/out cloudhv
	cp -r out/* $(@D) 
