# -*-makefile-*-
#
# Copyright (C) 2009 by Carsten Schlote <c.schlote@konzeptpark.de>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_ACL) += acl

#
# Paths and names
#
ACL_VERSION	:= 2.2.49
ACL_MD5		:= 181445894cca986da9ae0099d5ce2d08
ACL		:= acl-$(ACL_VERSION)
ACL_SUFFIX	:= tar.gz
ACL_URL		:= http://mirrors.zerg.biz/nongnu/acl/$(ACL).src.$(ACL_SUFFIX)
ACL_SOURCE	:= $(SRCDIR)/$(ACL).src.$(ACL_SUFFIX)
ACL_DIR		:= $(BUILDDIR)/$(ACL)
ACL_LICENSE	:= unknown

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

ACL_PATH	:= PATH=$(CROSS_PATH)
ACL_ENV 	:= $(CROSS_ENV)

ACL_INSTALL_OPT := \
	DIST_ROOT=$(ACL_PKGDIR) \
	install \
	install-lib \
	install-dev

#
# autoconf
#
ACL_AUTOCONF := \
	$(CROSS_AUTOCONF_USR) \
	--libexecdir=/usr/lib \
	--$(call ptx/endis, PTXCONF_ACL_SHARED)-shared \
	--$(call ptx/endis, PTXCONF_ACL_GETTEXT)-gettext

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/acl.targetinstall:
	@$(call targetinfo)

	@$(call install_init, acl)
	@$(call install_fixup, acl,PRIORITY,optional)
	@$(call install_fixup, acl,SECTION,base)
	@$(call install_fixup, acl,AUTHOR,"Carsten Schlote <c.schlote@konzeptpark.de>")
	@$(call install_fixup, acl,DESCRIPTION,missing)

ifdef PTXCONF_ACL_TOOLS
	@$(call install_copy, acl, 0, 0, 0755, -, /usr/bin/chacl)
	@$(call install_copy, acl, 0, 0, 0755, -, /usr/bin/setfacl)
	@$(call install_copy, acl, 0, 0, 0755, -, /usr/bin/getfacl)
endif
ifdef PTXCONF_ACL_SHARED
	@$(call install_lib, acl, 0, 0, 0644, libacl)
endif
	@$(call install_finish, acl)

	@$(call touch)

# vim: syntax=make
