# -*-makefile-*-
#
# Copyright (C) 2007 by Sascha Hauer
#               2009, 2010 by Marc Kleine-Budde <mkl@pengutronix.de>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_USBUTILS) += usbutils

#
# Paths and names
#
USBUTILS_VERSION	:= 004
USBUTILS_MD5		:= fc69cde51b2094aa4bbd804c0ba97e35
USBUTILS		:= usbutils-$(USBUTILS_VERSION)
USBUTILS_SUFFIX		:= tar.bz2
USBUTILS_URL		:= $(call ptx/mirror, KERNEL, utils/usb/usbutils/$(USBUTILS).$(USBUTILS_SUFFIX))
USBUTILS_SOURCE		:= $(SRCDIR)/$(USBUTILS).$(USBUTILS_SUFFIX)
USBUTILS_DIR		:= $(BUILDDIR)/$(USBUTILS)
USBUTILS_LICENSE	:= GPLv2

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

USBUTILS_PATH	:= PATH=$(CROSS_PATH)
USBUTILS_ENV 	:= $(CROSS_ENV)

#
# autoconf
#
USBUTILS_AUTOCONF := \
	$(CROSS_AUTOCONF_USR) \
	$(GLOBAL_LARGE_FILE_OPTION) \
	--disable-zlib

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/usbutils.targetinstall:
	@$(call targetinfo)

	@$(call install_init, usbutils)
	@$(call install_fixup, usbutils,PRIORITY,optional)
	@$(call install_fixup, usbutils,SECTION,base)
	@$(call install_fixup, usbutils,AUTHOR,"Robert Schwebel <r.schwebel@pengutronix.de>")
	@$(call install_fixup, usbutils,DESCRIPTION,missing)

ifdef PTXCONF_USBUTILS_LSUSB
	@$(call install_copy, usbutils, 0, 0, 0755, -, /usr/bin/lsusb)
endif
ifdef PTXCONF_USBUTILS_USBHIDDUMP
	@$(call install_copy, usbutils, 0, 0, 0755, -, /usr/bin/usbhid-dump)
endif
ifdef PTXCONF_USBUTILS_USBDEVICES
	@$(call install_copy, usbutils, 0, 0, 0755, -, /usr/bin/usb-devices)
endif
	@$(call install_copy, usbutils, 0, 0, 0644, -, /usr/share/usb.ids,n)

	@$(call install_finish, usbutils)

	@$(call touch)

# vim: syntax=make
