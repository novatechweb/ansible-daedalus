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
HOST_PACKAGES-$(PTXCONF_HOST_GETTEXT) += host-gettext

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

HOST_GETTEXT_CONF_ENV := \
	$(HOST_ENV) \
	ac_cv_header_iconv_h=no \
	am_cv_func_iconv=no \
	am_cv_lib_iconv=no

#
# autoconf
#
HOST_GETTEXT_AUTOCONF := \
	$(HOST_AUTOCONF) \
	--disable-csharp \
	--disable-java \
	--disable-static \
	--disable-libasprintf \
	--disable-native-java \
	--disable-openmp \
	--enable-relocatable \
	--without-emacs

# vim: syntax=make
