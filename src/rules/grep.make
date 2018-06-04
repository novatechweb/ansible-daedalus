# -*-makefile-*-
#
# Copyright (C) 2008 by Luotao Fu <l.fu@pengutronix.de>
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
PACKAGES-$(PTXCONF_GREP) += grep

#
# Paths and names
#
GREP_VERSION	:= 2.5.3
GREP_MD5	:= 27061ce1fde82876970b6549a156da8b
GREP		:= grep-$(GREP_VERSION)
GREP_SUFFIX	:= tar.bz2
GREP_URL	:= $(call ptx/mirror, GNU, grep/$(GREP).$(GREP_SUFFIX))
GREP_SOURCE	:= $(SRCDIR)/$(GREP).$(GREP_SUFFIX)
GREP_DIR	:= $(BUILDDIR)/$(GREP)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

GREP_PATH	:= PATH=$(CROSS_PATH)
GREP_ENV 	:= $(CROSS_ENV)

#
# autoconf
#
GREP_AUTOCONF := $(CROSS_AUTOCONF_ROOT)

ifdef PTXCONF_GREP_PCRE
GREP_AUTOCONF += --enable-perl-regexp
else
GREP_AUTOCONF += --disable-perl-regexp
endif

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/grep.targetinstall:
	@$(call targetinfo)

	@$(call install_init, grep)
	@$(call install_fixup, grep,PRIORITY,optional)
	@$(call install_fixup, grep,SECTION,base)
	@$(call install_fixup, grep,AUTHOR,"Luotao Fu <l.fu@pengutronix.de>")
	@$(call install_fixup, grep,DESCRIPTION,missing)

	@$(call install_copy, grep, 0, 0, 0755, -, /bin/grep)

	@$(call install_finish, grep)

	@$(call touch)

# vim: syntax=make
