# -*-makefile-*-
#
# Copyright (C) 2007 by Robert Schwebel
#               2009 by Marc Kleine-Budde <mkl@pengutronix.de>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_DBUS_GLIB) += dbus-glib

#
# Paths and names
#
DBUS_GLIB_VERSION	:= 0.100
DBUS_GLIB_MD5		:= d33959a9c0c6a158f5ac6d640316e89e
DBUS_GLIB		:= dbus-glib-$(DBUS_GLIB_VERSION)
DBUS_GLIB_SUFFIX	:= tar.gz
DBUS_GLIB_URL		:= http://dbus.freedesktop.org/releases/dbus-glib/$(DBUS_GLIB).$(DBUS_GLIB_SUFFIX)
DBUS_GLIB_SOURCE	:= $(SRCDIR)/$(DBUS_GLIB).$(DBUS_GLIB_SUFFIX)
DBUS_GLIB_DIR		:= $(BUILDDIR)/$(DBUS_GLIB)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

DBUS_GLIB_PATH	:= PATH=$(CROSS_PATH)
DBUS_GLIB_ENV	:= $(CROSS_ENV)

#
# autoconf
#
# use = here, not :=
DBUS_GLIB_AUTOCONF = \
	$(CROSS_AUTOCONF_USR) \
	--disable-bash-completion \
	--disable-gcov \
	--disable-gtk-doc \
	--disable-static \
	--disable-tests \
	--with-dbus-binding-tool=$(PTXCONF_SYSROOT_HOST)/bin/dbus-binding-tool \
	--with-introspect-xml=$(PTXCONF_SYSROOT_HOST)/share/dbus-glib/dbus-bus-introspect.xml

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/dbus-glib.targetinstall:
	@$(call targetinfo)

	@$(call install_init, dbus-glib)
	@$(call install_fixup, dbus-glib,PRIORITY,optional)
	@$(call install_fixup, dbus-glib,SECTION,base)
	@$(call install_fixup, dbus-glib,AUTHOR,"Robert Schwebel <r.schwebel@pengutronix.de>")
	@$(call install_fixup, dbus-glib,DESCRIPTION,missing)

	@$(call install_lib, dbus-glib, 0, 0, 0644, libdbus-glib-1)

	@$(call install_finish, dbus-glib)

	@$(call touch)

# vim: syntax=make
