# -*-makefile-*-
#
# Copyright (C) 2006 by Erwin Rol
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_XORG_LIB_XV) += xorg-lib-xv

#
# Paths and names
#
XORG_LIB_XV_VERSION	:= 1.0.7
XORG_LIB_XV_MD5		:= 5e1ac203ccd3ce3e89755ed1fbe75b0b
XORG_LIB_XV		:= libXv-$(XORG_LIB_XV_VERSION)
XORG_LIB_XV_SUFFIX	:= tar.bz2
XORG_LIB_XV_URL		:= $(call ptx/mirror, XORG, individual/lib/$(XORG_LIB_XV).$(XORG_LIB_XV_SUFFIX))
XORG_LIB_XV_SOURCE	:= $(SRCDIR)/$(XORG_LIB_XV).$(XORG_LIB_XV_SUFFIX)
XORG_LIB_XV_DIR		:= $(BUILDDIR)/$(XORG_LIB_XV)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

#
# autoconf
#
XORG_LIB_XV_CONF_TOOL	:= autoconf
XORG_LIB_XV_CONF_OPT	:= \
	$(CROSS_AUTOCONF_USR) \
	--disable-malloc0returnsnull

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/xorg-lib-xv.targetinstall:
	@$(call targetinfo)

	@$(call install_init, xorg-lib-xv)
	@$(call install_fixup, xorg-lib-xv,PRIORITY,optional)
	@$(call install_fixup, xorg-lib-xv,SECTION,base)
	@$(call install_fixup, xorg-lib-xv,AUTHOR,"Erwin Rol <ero@pengutronix.de>")
	@$(call install_fixup, xorg-lib-xv,DESCRIPTION,missing)

	@$(call install_lib, xorg-lib-xv, 0, 0, 0644, libXv)

	@$(call install_finish, xorg-lib-xv)

	@$(call touch)

# vim: syntax=make
