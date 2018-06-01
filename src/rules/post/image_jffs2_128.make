# -*-makefile-*-
#
# Copyright (C) 2003-2010 by the ptxdist project <ptxdist@pengutronix.de>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

SEL_ROOTFS-$(PTXCONF_IMAGE_JFFS2_128)	+= $(IMAGEDIR)/root.jffs2_128

$(IMAGEDIR)/root.jffs2_128: $(STATEDIR)/image_working_dir $(STATEDIR)/host-mtd-utils.install.post
	@echo -n "Creating root.jffs2_128 from working dir... "
	@echo -n "(--eraseblock=128 "
	@echo "--pad=0x01F80000 -b)"
	@cd $(image/work_dir);						\
	(awk -F: $(DOPERMISSIONS) $(image/permissions) &&		\
	(								\
		echo -n "$(PTXCONF_SYSROOT_HOST)/sbin/mkfs.jffs2 ";	\
		echo -n "-d $(image/work_dir) ";			\
		echo -n "--eraseblock=128 "; \
		echo -n "--pad=0x01F80000 -b ";\
		echo  "-o $(IMAGEDIR)/root.jffs2_128" ) | tee -a "$(PTX_LOGFILE)"		\
	) | $(FAKEROOT) --
	@echo "done."

# vim: syntax=make
