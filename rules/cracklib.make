# -*-makefile-*-
#
# Copyright (C) 2010 by Joseph <Joseph.Lutz@novatechweb.com>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_CRACKLIB) += cracklib

#
# Paths and names
#
CRACKLIB_VERSION	:= 2.8.18
CRACKLIB_MD5		:= 79053ad8bc714a44cd660cb12116211b
CRACKLIB		:= cracklib-$(CRACKLIB_VERSION)
CRACKLIB_SUFFIX		:= tar.gz
CRACKLIB_URL		:= http://downloads.sourceforge.net/project/cracklib/cracklib/2.8.18/$(CRACKLIB).$(CRACKLIB_SUFFIX)
CRACKLIB_SOURCE		:= $(SRCDIR)/$(CRACKLIB).$(CRACKLIB_SUFFIX)
CRACKLIB_DIR		:= $(BUILDDIR)/$(CRACKLIB)
CRACKLIB_LICENSE	:= GPLv2+

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

#
# autoconf
#
CRACKLIB_CONF_TOOL	:= autoconf
CRACKLIB_CONF_OPT	:= $(CROSS_AUTOCONF_USR) \
	--prefix=/ \
	--sbindir=/usr/sbin \
	--with-default-dict=/lib/cracklib/pw_dict

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/cracklib.targetinstall:
	@$(call targetinfo)

	@$(call install_init, cracklib)
	@$(call install_fixup, cracklib,PRIORITY,optional)
	@$(call install_fixup, cracklib,SECTION,base)
	@$(call install_fixup, cracklib,AUTHOR,"Joseph <Joseph.Lutz@novatechweb.com>")
	@$(call install_fixup, cracklib,DESCRIPTION,missing)

	@$(call install_lib, cracklib, 0, 0, 0644, libcrack)

ifdef PTXCONF_CRACKLIB_CRACKLIB_UTILS
	@$(call install_copy, cracklib, 0, 0, 0755, -, /usr/sbin/cracklib-packer)
	@$(call install_copy, cracklib, 0, 0, 0755, -, /usr/sbin/cracklib-unpacker)
	@$(call install_copy, cracklib, 0, 0, 0755, -, /usr/sbin/cracklib-check)
	@$(call install_copy, cracklib, 0, 0, 0755, -, /usr/sbin/create-cracklib-dict)
	@$(call install_copy, cracklib, 0, 0, 0755, -, /usr/sbin/cracklib-format)
endif

ifdef PTXCONF_CRACKLIB_DICT
	@$(call install_alternative, cracklib, 0, 0, 0644, /lib/cracklib/pw_dict.hwm)
	@$(call install_alternative, cracklib, 0, 0, 0644, /lib/cracklib/pw_dict.pwd)
	@$(call install_alternative, cracklib, 0, 0, 0644, /lib/cracklib/pw_dict.pwi)
endif

	@$(call install_finish, cracklib)

	@$(call touch)

# vim: syntax=make
