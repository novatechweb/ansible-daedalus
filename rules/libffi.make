# -*-makefile-*-
#
# Copyright (C) 2008 by Robert Schwebel <r.schwebel@pengutronix.de>
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
PACKAGES-$(PTXCONF_LIBFFI) += libffi

#
# Paths and names
#
LIBFFI_VERSION	:= 3.0.11
LIBFFI_MD5	:= f69b9693227d976835b4857b1ba7d0e3
LIBFFI		:= libffi-$(LIBFFI_VERSION)
LIBFFI_SUFFIX	:= tar.gz
LIBFFI_SOURCE	:= $(SRCDIR)/$(LIBFFI).$(LIBFFI_SUFFIX)
LIBFFI_DIR	:= $(BUILDDIR)/$(LIBFFI)

LIBFFI_URL	:= \
	http://ftp.gwdg.de/pub/linux/sources.redhat.com/libffi/$(LIBFFI).$(LIBFFI_SUFFIX) \
	ftp://sourceware.org/pub/libffi/$(LIBFFI).$(LIBFFI_SUFFIX)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

LIBFFI_CONF_TOOL := autoconf

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/libffi.install:
	@$(call targetinfo)
	@$(call install, LIBFFI)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/libffi.targetinstall:
	@$(call targetinfo)

	@$(call install_init, libffi)
	@$(call install_fixup, libffi,PRIORITY,optional)
	@$(call install_fixup, libffi,SECTION,base)
	@$(call install_fixup, libffi,AUTHOR,"Robert Schwebel <r.schwebel@pengutronix.de>")
	@$(call install_fixup, libffi,DESCRIPTION,missing)

	@$(call install_lib, libffi, 0, 0, 0644, libffi)

	@$(call install_finish, libffi)

	@$(call touch)

# vim: syntax=make
