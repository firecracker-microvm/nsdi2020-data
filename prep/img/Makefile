
TARGETS := ../../img/boot-time-vmlinux
TARGETS += ../../img/boot-time-vmlinuz
TARGETS += ../../img/boot-time-initrd.img
TARGETS += ../../img/boot-time-disk.img

LK := ../../bin/linuxkit

build: ../../img $(TARGETS)

../../img:
	mkdir -p $@

../../img/boot-time-vmlinux: boot-time.yml
	$(LK) build -format kernel+initrd -decompress-kernel $<
	cp boot-time-kernel $@

../../img/boot-time-initrd.img: ../../img/boot-time-vmlinuz
../../img/boot-time-vmlinuz: boot-time.yml
	$(LK) build -format kernel+initrd $<
	cp boot-time-kernel $@
	cp boot-time-initrd.img $(@D)

../../img/boot-time-disk.img: boot-time.yml
	$(LK) build -format raw-bios $<
	cp boot-time-bios.img $@
