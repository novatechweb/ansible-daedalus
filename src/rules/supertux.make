# -*-makefile-*-
#
# Copyright (C) 2008 by SuperTux Team
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_SUPERTUX) += supertux

#
# Paths and names
#
SUPERTUX_VERSION	:= 0.1.3
SUPERTUX_MD5		:= f2fc288459f33d5cd8f645fbca737a63
SUPERTUX		:= supertux-$(SUPERTUX_VERSION)
SUPERTUX_SUFFIX		:= tar.bz2
SUPERTUX_URL		:= http://download.berlios.de/supertux/$(SUPERTUX).$(SUPERTUX_SUFFIX)
SUPERTUX_SOURCE		:= $(SRCDIR)/$(SUPERTUX).$(SUPERTUX_SUFFIX)
SUPERTUX_DIR		:= $(BUILDDIR)/$(SUPERTUX)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

SUPERTUX_PATH	:= PATH=$(CROSS_PATH)
SUPERTUX_ENV 	:= $(CROSS_ENV)

#
# autoconf
#
SUPERTUX_AUTOCONF := \
	$(CROSS_AUTOCONF_USR) \
	--disable-opengl \
	--with-sdl-prefix=$(SYSROOT)/usr

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/supertux.targetinstall:
	@$(call targetinfo)

	@$(call install_init, supertux)
	@$(call install_fixup, supertux,PRIORITY,optional)
	@$(call install_fixup, supertux,SECTION,base)
	@$(call install_fixup, supertux,AUTHOR,"Marek Moeckel")
	@$(call install_fixup, supertux,DESCRIPTION,missing)

	@cd $(PKGDIR)/$(SUPERTUX); \
		for file in `find -type f -perm 644`; do \
			$(call install_copy, supertux, 0, 0, 0644, $(PKGDIR)/$(SUPERTUX)/$$file, /$$file, n); \
		done
	@$(call install_copy, supertux, 0, 0, 0755, $(PKGDIR)/$(SUPERTUX)/usr/bin/supertux, /usr/bin/supertux)

	@$(call install_finish, supertux)

	@$(call touch)

# vim: syntax=make
