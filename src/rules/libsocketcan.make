# -*-makefile-*-
#
# Copyright (C) 2009 by Luotao Fu <l.fu@pengutronix.de>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_LIBSOCKETCAN) += libsocketcan

#
# Paths and names
#
LIBSOCKETCAN_VERSION	:= 0.0.9
LIBSOCKETCAN_MD5	:= cd92766be40d98b5cb08366b71ea4663
LIBSOCKETCAN		:= libsocketcan-$(LIBSOCKETCAN_VERSION)
LIBSOCKETCAN_SUFFIX	:= tar.bz2
LIBSOCKETCAN_URL	:= http://www.pengutronix.de/software/libsocketcan/download/$(LIBSOCKETCAN).$(LIBSOCKETCAN_SUFFIX)
LIBSOCKETCAN_SOURCE	:= $(SRCDIR)/$(LIBSOCKETCAN).$(LIBSOCKETCAN_SUFFIX)
LIBSOCKETCAN_DIR	:= $(BUILDDIR)/$(LIBSOCKETCAN)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

LIBSOCKETCAN_PATH	:= PATH=$(CROSS_PATH)
LIBSOCKETCAN_ENV 	:= $(CROSS_ENV)

#
# autoconf
#
LIBSOCKETCAN_AUTOCONF := $(CROSS_AUTOCONF_USR)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/libsocketcan.targetinstall:
	@$(call targetinfo)

	@$(call install_init, libsocketcan)
	@$(call install_fixup, libsocketcan,PRIORITY,optional)
	@$(call install_fixup, libsocketcan,SECTION,base)
	@$(call install_fixup, libsocketcan,AUTHOR,"Luotao Fu <l.fu@pengutronix.de>")
	@$(call install_fixup, libsocketcan,DESCRIPTION,missing)

	@$(call install_lib, libsocketcan, 0, 0, 0644, libsocketcan)

	@$(call install_finish, libsocketcan)

	@$(call touch)

# vim: syntax=make
