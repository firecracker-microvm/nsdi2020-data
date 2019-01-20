DIRS = $(dir $(shell find . -maxdepth 2 -mindepth 2 -type f -name build.yml))
.PHONY: push force-push build forcebuild show-tag clean

ORG ?= rneugeba

push:
	@set -e; for d in $(DIRS); do linuxkit pkg push --org $(ORG) --enable-content-trust=false "$$d"; done

build:
	@set -e; for d in $(DIRS); do linuxkit pkg build --org $(ORG) --enable-content-trust=false "$$d"; done

show-tag:
	@set -e; for d in $(DIRS); do linuxkit pkg show-tag --org $(ORG) --enable-content-trust=false "$$d"; done

clean:
