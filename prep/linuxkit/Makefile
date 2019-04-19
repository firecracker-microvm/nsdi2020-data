# Quick hacky makefile to build linuxkit with docker

URL := https://github.com/linuxkit/linuxkit/releases/download/v0.7/linuxkit-linux-amd64

../../bin/linuxkit:
	curl -fsSL -o $@ $(URL)
	chmod ugo+x $@
