# -*-makefile-*-
#
# Copyright (C) 2007 by Sascha Hauer
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_IPERF) += iperf

#
# Paths and names
#
IPERF_VERSION	:= 2.0.4
IPERF_MD5	:= 8c5bc14cc2ea55f18f22afe3c23e3dcb
IPERF		:= iperf-$(IPERF_VERSION)
IPERF_SUFFIX	:= tar.gz
IPERF_URL	:= $(call ptx/mirror, SF, iperf/$(IPERF).$(IPERF_SUFFIX))
IPERF_SOURCE	:= $(SRCDIR)/$(IPERF).$(IPERF_SUFFIX)
IPERF_DIR	:= $(BUILDDIR)/$(IPERF)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

IPERF_PATH	:= PATH=$(CROSS_PATH)
IPERF_ENV 	:= $(CROSS_ENV)

#
# autoconf
#
IPERF_AUTOCONF := \
	$(CROSS_AUTOCONF_USR) \
	$(GLOBAL_IPV6_OPTION)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/iperf.targetinstall:
	@$(call targetinfo)

	@$(call install_init, iperf)
	@$(call install_fixup, iperf,PRIORITY,optional)
	@$(call install_fixup, iperf,SECTION,base)
	@$(call install_fixup, iperf,AUTHOR,"Robert Schwebel <r.schwebel@pengutronix.de>")
	@$(call install_fixup, iperf,DESCRIPTION,missing)

	@$(call install_copy, iperf, 0, 0, 0755, -, /usr/bin/iperf)

	@$(call install_finish, iperf)

	@$(call touch)

# vim: syntax=make
