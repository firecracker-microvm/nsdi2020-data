
TARGETS := ../../img/boot-time-vmlinux
TARGETS += ../../img/boot-time-vmlinuz
TARGETS += ../../img/boot-time-initrd.img
TARGETS += ../../img/boot-time-disk.img

TARGETS := ../../img/boot-time-pci-vmlinux
TARGETS += ../../img/boot-time-pci-vmlinuz
TARGETS += ../../img/boot-time-pci-initrd.img
TARGETS += ../../img/boot-time-pci-disk.img

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

../../img/boot-time-pci-vmlinux: boot-time-pci.yml
	$(LK) build -format kernel+initrd -decompress-kernel $<
	cp boot-time-pci-kernel $@
../../img/boot-time-pci-initrd.img: ../../img/boot-time-pci-vmlinuz
../../img/boot-time-pci-vmlinuz: boot-time-pci.yml
	$(LK) build -format kernel+initrd $<
	cp boot-time-pci-kernel $@
	cp boot-time-pci-initrd.img $(@D)
../../img/boot-time-pci-disk.img: boot-time-pci.yml
	$(LK) build -format raw-bios $<
	cp boot-time-pci-bios.img $@
