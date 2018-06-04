# -*-makefile-*-
#
# Copyright (C) 2006 by Erwin Rol
#           (C) 2010 by Michael Olbrich <m.olbrich@pengutronix.de>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_XORG_DRIVER_VIDEO_DUMMY) += xorg-driver-video-dummy

#
# Paths and names
#
XORG_DRIVER_VIDEO_DUMMY_VERSION	:= 0.3.5
XORG_DRIVER_VIDEO_DUMMY_MD5	:= 89701f372eed9ed541cf00d57c78e7ef
XORG_DRIVER_VIDEO_DUMMY		:= xf86-video-dummy-$(XORG_DRIVER_VIDEO_DUMMY_VERSION)
XORG_DRIVER_VIDEO_DUMMY_SUFFIX	:= tar.bz2
XORG_DRIVER_VIDEO_DUMMY_URL	:= $(call ptx/mirror, XORG, individual/driver/$(XORG_DRIVER_VIDEO_DUMMY).$(XORG_DRIVER_VIDEO_DUMMY_SUFFIX))
XORG_DRIVER_VIDEO_DUMMY_SOURCE	:= $(SRCDIR)/$(XORG_DRIVER_VIDEO_DUMMY).$(XORG_DRIVER_VIDEO_DUMMY_SUFFIX)
XORG_DRIVER_VIDEO_DUMMY_DIR	:= $(BUILDDIR)/$(XORG_DRIVER_VIDEO_DUMMY)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

#
# autoconf
#
XORG_DRIVER_VIDEO_DUMMY_CONF_TOOL := autoconf

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/xorg-driver-video-dummy.targetinstall:
	@$(call targetinfo)

	@$(call install_init, xorg-driver-video-dummy)
	@$(call install_fixup, xorg-driver-video-dummy,PRIORITY,optional)
	@$(call install_fixup, xorg-driver-video-dummy,SECTION,base)
	@$(call install_fixup, xorg-driver-video-dummy,AUTHOR,"Erwin Rol <ero@pengutronix.de>")
	@$(call install_fixup, xorg-driver-video-dummy,DESCRIPTION,missing)

	@$(call install_copy, xorg-driver-video-dummy, 0, 0, 0755, -, \
		/usr/lib/xorg/modules/drivers/dummy_drv.so)

	@$(call install_finish, xorg-driver-video-dummy)

	@$(call touch)

# vim: syntax=make
