# -*-makefile-*-
#
# Copyright (C) 2003 by Ixia Corporation, by Milan Bobde
#		2007 by Pengutronix e.K.
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
PACKAGES-$(PTXCONF_PROCPS) += procps

#
# Paths and names
#
PROCPS_VERSION	:= 3.2.8
PROCPS_MD5	:= 9532714b6846013ca9898984ba4cd7e0
PROCPS		:= procps-$(PROCPS_VERSION)
PROCPS_SUFFIX	:= tar.gz
PROCPS_URL	:= http://procps.sourceforge.net/$(PROCPS).$(PROCPS_SUFFIX)
PROCPS_SOURCE	:= $(SRCDIR)/$(PROCPS).$(PROCPS_SUFFIX)
PROCPS_DIR	:= $(BUILDDIR)/$(PROCPS)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# build only the required parts
PROCPS_ALL-$(PTXCONF_PROCPS_TOP)	+= $(PROCPS_PKGDIR)/usr/bin/top
PROCPS_ALL-$(PTXCONF_PROCPS_SLABTOP)	+= $(PROCPS_PKGDIR)/usr/bin/slabtop
PROCPS_ALL-$(PTXCONF_PROCPS_SYSCTL)	+= $(PROCPS_PKGDIR)/sbin/sysctl
PROCPS_ALL-$(PTXCONF_PROCPS_W)		+= $(PROCPS_PKGDIR)/usr/bin/w
PROCPS_ALL-$(PTXCONF_PROCPS_PGREP)	+= $(PROCPS_PKGDIR)/usr/bin/pgrep

PROCPS_PATH	:= PATH=$(CROSS_PATH)
PROCPS_MAKEVARS	:= \
	CC="$(CROSS_CC)" \
	CFLAGS=-O2 \
	CPPFLAGS='$(CROSS_CPPFLAGS)' \
	LDFLAGS='$(CROSS_LDFLAGS)' \
	lib64=$(CROSS_LIB_DIR) \
	ldconfig=true \
	MANFILES="" \
	BINFILES="$(PROCPS_ALL-y)"

$(STATEDIR)/procps.prepare:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/procps.targetinstall:
	@$(call targetinfo)

	@$(call install_init, procps)
	@$(call install_fixup, procps,PRIORITY,optional)
	@$(call install_fixup, procps,SECTION,base)
	@$(call install_fixup, procps,AUTHOR,"Robert Schwebel <r.schwebel@pengutronix.de>")
	@$(call install_fixup, procps,DESCRIPTION,missing)

	@$(call install_lib, procps, 0, 0, 0644, libproc-3.2.8)

ifdef PTXCONF_PROCPS_TOP
	@$(call install_copy, procps, 0, 0, 0755, -,\
		/usr/bin/top)
endif
ifdef PTXCONF_PROCPS_SLABTOP
	@$(call install_copy, procps, 0, 0, 0755, -, \
		/usr/bin/slabtop)
endif
ifdef PTXCONF_PROCPS_SYSCTL
	@$(call install_copy, procps, 0, 0, 0755, -, \
		/sbin/sysctl)

	@$(call install_alternative, procps, 0, 0, 0644, /etc/sysctl.conf, n)
endif
ifdef PTXCONF_PROCPS_PS
	@$(call install_copy, procps, 0, 0, 0755, -, \
		/bin/ps)
endif
ifdef PTXCONF_PROCPS_W
	@$(call install_copy, procps, 0, 0, 0755, -, \
		/usr/bin/w)
endif
ifdef PTXCONF_PROCPS_PGREP
	@$(call install_copy, procps, 0, 0, 0755, -, \
		/usr/bin/pgrep)
endif
	@$(call install_finish, procps)

	@$(call touch)

# vim: syntax=make
