# -*-makefile-*-
#
# Copyright (C) 2005 by Robert Schwebel
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
PACKAGES-$(PTXCONF_LIBPV) += libpv

#
# Paths and names
#
LIBPV_VERSION	:= 1.4.1
LIBPV_MD5	:= f3a1073174f676a6a64dba7b2e55b247
LIBPV		:= libpv-$(LIBPV_VERSION)
LIBPV_SUFFIX	:= tar.bz2
LIBPV_URL	:= http://www.pengutronix.de/software/libpv/download/$(LIBPV).$(LIBPV_SUFFIX)
LIBPV_SOURCE	:= $(SRCDIR)/$(LIBPV).$(LIBPV_SUFFIX)
LIBPV_DIR	:= $(BUILDDIR)/$(LIBPV)


# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

#
# autoconf
#
LIBPV_CONF_TOOL	:= autoconf

# force disable xsltproc to avoid building docs
LIBPV_CONF_ENV	:= \
	$(CROSS_ENV) \
	ac_cv_prog_XSLTPROC=false

LIBPV_CONF_OPT := \
	$(CROSS_AUTOCONF_USR) \
	--enable-shared \
	--enable-static \
	--disable-debug \
	--$(call ptx/endis, PTXCONF_LIBPV_EVENT)-event \
	--$(call ptx/endis, PTXCONF_LIBPV_PYTHON)-python \
	--$(call ptx/wwo, PTXCONF_LIBPV_XML_EXPAT)-expat

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/libpv.targetinstall:
	@$(call targetinfo)

	@$(call install_init, libpv)
	@$(call install_fixup, libpv,PRIORITY,optional)
	@$(call install_fixup, libpv,SECTION,base)
	@$(call install_fixup, libpv,AUTHOR,"Robert Schwebel <r.schwebel@pengutronix.de>")
	@$(call install_fixup, libpv,DESCRIPTION,missing)

	@$(call install_lib, libpv, 0, 0, 0644, libpv)

ifdef PTXCONF_LIBPV_PVTOOL
	@$(call install_copy, libpv, 0, 0, 0755, -, /usr/bin/pvtool)
endif
ifdef PTXCONF_LIBPV_EVENT
	@$(call install_copy, libpv, 0, 0, 0755, -, \
		/usr/bin/pv_eventd)
endif

ifdef PTXCONF_LIBPV_PYTHON
	@$(call install_copy, libpv, 0, 0, 0644, -, \
		/usr/lib/python$(PYTHON_MAJORMINOR)/site-packages/libpv.so)
endif
	@$(call install_finish, libpv)

	@$(call touch)

# vim: syntax=make
