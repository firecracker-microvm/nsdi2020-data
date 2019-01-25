
TARGETS := ../../img

TARGETS += ../../img/boot-time-vmlinux
TARGETS += ../../img/boot-time-vmlinuz

TARGETS += ../../img/boot-time-pci-vmlinux
TARGETS += ../../img/boot-time-pci-vmlinuz

TARGETS += ../../img/boot-time-initrd.img
TARGETS += ../../img/boot-time-disk.img

LK := ../../bin/linuxkit
LOOP ?= /dev/loop0

build: $(TARGETS)

../../img:
	mkdir -p $@


../../img/boot-time-vmlinux: boot-time.yml
	$(LK) build -format kernel+initrd -decompress-kernel $<
	cp boot-time-kernel $@
../../img/boot-time-vmlinuz: boot-time.yml
	$(LK) build -format kernel+initrd $<
	cp boot-time-kernel $@

../../img/boot-time-pci-vmlinux: boot-time-pci.yml
	$(LK) build -format kernel+initrd -decompress-kernel $<
	cp boot-time-pci-kernel $@
../../img/boot-time-pci-vmlinuz: boot-time-pci.yml
	$(LK) build -format kernel+initrd $<
	cp boot-time-pci-kernel $@


../../img/boot-time-initrd.img: boot-time.yml
	$(LK) build -format kernel+initrd $<
	cp boot-time-initrd.img $@

../../img/boot-time-disk.img: boot-time.tar
	sudo losetup -d $(LOOP) || true
	dd if=/dev/zero of=$(@F) bs=100M count=10
	mkfs.ext4 $(@F)
	sudo losetup $(LOOP) $(@F)
	mkdir boot-time.img
	sudo mount $(LOOP) boot-time.img
	sudo tar xf boot-time.tar -C boot-time.img
	sudo umount boot-time.img
	sudo losetup -d $(LOOP)
	rmdir boot-time.img
	cp $(@F) $@
boot-time.tar: boot-time.yml
	$(LK) build -format tar $<
