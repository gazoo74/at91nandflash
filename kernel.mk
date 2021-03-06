OUTPUTDIR	?= output

KIMAGE		?= zImage
KDEFCONFIG	?= sama5_defconfig
DTB		?= $(shell echo $(BOARD) | sed -e '/at91-sam9/s,at91-,at91,' -e '/at91-sama5d3[1-6]ek/s,at91-,,')
KOUTPUT		?= $(OUTPUTDIR)/linux-$(karch)-$(ksoc)

linux/Makefile:
	@echo "You need to provide your own kernel sources into the $(CURDIR)/$(@D) directory!" >&2
	@echo "Have a look at https://www.kernel.org! or run the command below:" >&2
	@echo "$$ git clone git@github.com:torvalds/linux.git $(CURDIR)/$(@D)" >&2
	@exit 1

$(KOUTPUT)/.config: linux/Makefile
	@echo "Configuring $(@D) using $(KDEFCONFIG)..."
	install -d $(@D)
	echo "# Generated by at91nandflash." >$(@D)/$(karch)-$(ksoc)_defconfig
	for cfg in $(KEXTRACFG); do echo $$cfg >>$(KOUTPUT)/$(karch)-$(ksoc)_defconfig; done
	make -C linux O=$(CURDIR)/$(KOUTPUT) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) $(KDEFCONFIG)
	cd linux && ARCH=arm scripts/kconfig/merge_config.sh -O $(CURDIR)/$(KOUTPUT) $(CURDIR)/$@ $(CURDIR)/$(KOUTPUT)/$(karch)-$(ksoc)_defconfig
	for cfg in $(KEXTRACFG); do grep -E "$$cfg" $(KOUTPUT)/$(karch)-$(ksoc)_defconfig; done

$(KOUTPUT)/arch/arm/boot/$(KIMAGE): initramfs.cpio $(KOUTPUT)/.config
	@echo "Compiling $(@F)..."
	make -C linux O=$(CURDIR)/$(KOUTPUT) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) CONFIG_INITRAMFS_SOURCE=$(CURDIR)/$< $(@F)

$(KIMAGE)-initramfs-$(BOARD).bin: $(KOUTPUT)/arch/arm/boot/$(KIMAGE)
	cp $< $@

kernel: $(KIMAGE)-initramfs-$(BOARD).bin

kernel_% linux_%:
	make -C linux O=$(CURDIR)/$(KOUTPUT) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) $*

$(KOUTPUT)/arch/arm/boot/dts/%.dtb:
	make -C linux O=$(CURDIR)/$(KOUTPUT) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) $(<F)

$(DTB).dtb: $(KOUTPUT)/arch/arm/boot/dts/$(DTB).dtb
	cp $< .

dtb: $(DTB).dtb

dtbs: linux_dtbs

kernel_menuconfig linux_menuconfig:

kernel_configure linux_configure:
	make -f Makefile $(KOUTPUT)/.config

kernel_compile linux_compile:
	make -f Makefile $(KOUTPUT)/arch/arm/boot/$(KIMAGE)

kernel_clean linux_clean:
	make -C linux mrproper

clean::
	rm -f $(KIMAGE)-initramfs-$(BOARD).bin $(DTB).dtb

cleanall::
	rm -rf $(KOUTPUT)/

mrproper::
	rm -f $(KIMAGE)-initramfs-*.bin *.dtb
	rm -rf $(OUTPUTDIR)/linux-*/
