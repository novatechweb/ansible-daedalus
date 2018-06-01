# -*-makefile-*-
#
# Copyright (C) 2008 by Robert Schwebel <r.schwebel@pengutronix.de>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_OWFS) += owfs

#
# Paths and names
#
OWFS_VERSION	:= 2.8p6
OWFS_MD5	:= ffd2cec1ceeccfd911b4f181b66829c2
OWFS		:= owfs-$(OWFS_VERSION)
OWFS_SUFFIX	:= tar.gz
OWFS_URL	:= $(call ptx/mirror, SF, owfs/$(OWFS).$(OWFS_SUFFIX))
OWFS_SOURCE	:= $(SRCDIR)/$(OWFS).$(OWFS_SUFFIX)
OWFS_DIR	:= $(BUILDDIR)/$(OWFS)
OWFS_LICENSE	:= GPLv2+, LGPLv2+

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

#
# autoconf
#
OWFS_AUTOCONF := \
	$(CROSS_AUTOCONF_USR) \
	--disable-debian \
	--disable-debug \
	--enable-owlib \
	--disable-tai8570 \
	--disable-thermocouple \
	--enable-mt \
	--disable-i2c \
	--disable-ha7 \
	--disable-w1 \
	--disable-owhttpd \
	--disable-owftpd \
	--disable-owserver \
	--disable-ownet \
	--disable-owtap \
	--disable-owmalloc \
	--disable-owtraffic \
	--disable-owmon \
	--disable-owcapi \
	--disable-swig \
	--disable-owperl \
	--disable-owphp \
	--disable-owpython \
	--disable-owtcl \
	--disable-profiling \
	--disable-cache \
	--disable-zero \
	--disable-usb \
	--disable-parport \
	--without-perl5 \
	--without-php \
	--without-phpconfig \
	--without-python \
	--without-pythonconfig \
	--without-tcl

ifdef PTXCONF_OWFS_OWSHELL
OWFS_AUTOCONF += --enable-owshell
else
OWFS_AUTOCONF += --disable-owshell
endif
ifdef PTXCONF_OWFS_OWNETLIB
OWFS_AUTOCONF += --enable-ownetlib
else
OWFS_AUTOCONF += --disable-ownetlib
endif
ifdef PTXCONF_OWFS_OWFS
OWFS_AUTOCONF += --enable-owfs
else
OWFS_AUTOCONF += --disable-owfs
endif

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/owfs.targetinstall:
	@$(call targetinfo)

	@$(call install_init, owfs)
	@$(call install_fixup, owfs,PRIORITY,optional)
	@$(call install_fixup, owfs,SECTION,base)
	@$(call install_fixup, owfs,AUTHOR,"Robert Schwebel <r.schwebel@pengutronix.de>")
	@$(call install_fixup, owfs,DESCRIPTION,missing)

	@$(call install_lib, owfs, 0, 0, 0644, libow-2.8)

ifdef PTXCONF_OWFS_OWFS
	@$(call install_copy, owfs, 0, 0, 0755, -, /usr/bin/owfs)
endif
	@$(call install_finish, owfs)

	@$(call touch)

# vim: syntax=make
