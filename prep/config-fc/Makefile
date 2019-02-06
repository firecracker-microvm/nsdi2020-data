.PHONY: build
build: ../../bin/config-fc

../../bin/config-fc: config-fc.go Makefile
	go build config-fc.go
	mkdir -p $(@D)
	cp $(@F) $(@D)
