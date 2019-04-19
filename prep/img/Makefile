
TARGETS := ../../img

TARGETS += ../../img/boot-time-vmlinux
TARGETS += ../../img/boot-time-vmlinuz

TARGETS += ../../img/boot-time-pci-vmlinux
TARGETS += ../../img/boot-time-pci-vmlinuz

TARGETS += ../../img/boot-time-linuxkit-vmlinux

TARGETS += ../../img/boot-time-initrd.img
TARGETS += ../../img/boot-time-disk.img

TARGETS += ../../img/bench-ssh-vmlinux
TARGETS += ../../img/bench-ssh-vmlinuz
TARGETS += ../../img/bench-ssh-disk.img

LK := ../../bin/linuxkit
LOOP ?= /dev/loop0

build: $(TARGETS)

../../img:
	mkdir -p $@

../../img/boot-time-vmlinux: boot-time.yml
	$(LK) build -format kernel+initrd -decompress-kernel $<
	mv boot-time-kernel $@
../../img/boot-time-vmlinuz: boot-time.yml
	$(LK) build -format kernel+initrd $<
	mv boot-time-kernel $@

../../img/boot-time-pci-vmlinux: boot-time-pci.yml
	$(LK) build -format kernel+initrd -decompress-kernel $<
	mv boot-time-pci-kernel $@
../../img/boot-time-pci-vmlinuz: boot-time-pci.yml
	$(LK) build -format kernel+initrd $<
	mv boot-time-pci-kernel $@

../../img/boot-time-linuxkit-vmlinux: boot-time-linuxkit.yml
	$(LK) build -format kernel+initrd -decompress-kernel $<
	mv boot-time-linuxkit-kernel $@


../../img/boot-time-initrd.img: boot-time.yml
	$(LK) build -format kernel+initrd $<
	mv boot-time-initrd.img $@

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
	mv $(@F) $@
	rm boot-time.tar
boot-time.tar: boot-time.yml
	$(LK) build -format tar $<


../../img/bench-ssh-vmlinux: bench-ssh.yml
	$(LK) build -format kernel+initrd -decompress-kernel $<
	cp bench-ssh-kernel $@
../../img/bench-ssh-vmlinuz: bench-ssh.yml
	$(LK) build -format kernel+initrd $<
	mv bench-ssh-kernel $@

../../img/bench-ssh-disk.img: bench-ssh.tar
	sudo losetup -d $(LOOP) || true
	dd if=/dev/zero of=$(@F) bs=100M count=10
	mkfs.ext4 $(@F)
	sudo losetup $(LOOP) $(@F)
	mkdir bench-ssh.img
	sudo mount $(LOOP) bench-ssh.img
	sudo tar xf bench-ssh.tar -C bench-ssh.img
	sudo umount bench-ssh.img
	sudo losetup -d $(LOOP)
	rmdir bench-ssh.img
	mv $(@F) $@
	rm bench-ssh.tar
bench-ssh.tar: bench-ssh.yml
	$(LK) build -format tar $<
