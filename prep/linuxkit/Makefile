# Quick hacky makefile to build linuxkit with docker

LK_COMMIT := 9a818a1446d6
../../bin/linuxkit: linuxkit/bin/linuxkit
	mkdir -p $(@D)
	cp $< $(@D)

linuxkit/bin/linuxkit: linuxkit
	cd $< && git checkout $(LK_COMMIT)
	cd $< && make bin/linuxkit

linuxkit:
	git clone https://github.com/linuxkit/linuxkit.git

clean:
	rm -rf linuxkit
