# -*-makefile-*-
#
# Copyright (C) 2008 by Robert Schwebel
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_GST_FFMPEG) += gst-ffmpeg

#
# Paths and names
#
GST_FFMPEG_VERSION	:= 0.10.11
GST_FFMPEG		:= gst-ffmpeg-$(GST_FFMPEG_VERSION)
GST_FFMPEG_MD5		:= 0d23197ba7ac06ea34fa66d38469ebe5
GST_FFMPEG_SUFFIX		:= tar.bz2
GST_FFMPEG_URL		:= http://gstreamer.freedesktop.org/src/gst-ffmpeg/$(GST_FFMPEG).$(GST_FFMPEG_SUFFIX)
GST_FFMPEG_SOURCE		:= $(SRCDIR)/$(GST_FFMPEG).$(GST_FFMPEG_SUFFIX)
GST_FFMPEG_DIR		:= $(BUILDDIR)/$(GST_FFMPEG)

# ----------------------------------------------------------------------------
# Get
# ----------------------------------------------------------------------------

$(GST_FFMPEG_SOURCE):
	@$(call targetinfo)
	@$(call get, GST_FFMPEG)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

#
# autoconf
#
GST_FFMPEG_AUTOCONF := \
	$(CROSS_AUTOCONF_USR) \
	$(GLOBAL_LARGE_FILE_OPTION) \
	--enable-option-checking \
	--enable-silent-rules \
	--disable-nls \
	--disable-rpath \
	--disable-debug \
	--disable-profiling \
	--disable-valgrind \
	--disable-gcov \
	--disable-examples \
	--enable-external \
	--disable-experimental \
	--disable-gtk-doc \
	--disable-gobject-cast-checks \
	--disable-oggtest \
	--disable-vorbistest \
	--disable-freetypetest \
	--without-libiconv-prefix \
	--without-libintl-prefix \
	--with-ffmpeg-extra-configure="--target-os=gnu --disable-mmx --enable-libfaad --enable-libvpx --enable-libtheora --enable-libvorbis"

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/gst-ffmpeg.targetinstall:
	@$(call targetinfo)

	@$(call install_init,  gst-ffmpeg)
	@$(call install_fixup, gst-ffmpeg,PRIORITY,optional)
	@$(call install_fixup, gst-ffmpeg,SECTION,base)
	@$(call install_fixup, gst-ffmpeg,AUTHOR,"Robert Schwebel <r.schwebel@pengutronix.de>")
	@$(call install_fixup, gst-ffmpeg,DESCRIPTION,missing)
	
	@$(call install_copy, gst-ffmpeg, 0, 0, 0644, -, \
		/usr/lib/gstreamer-0.10/libgstffmpegscale.so)
	@$(call install_copy, gst-ffmpeg, 0, 0, 0644, -, \
		/usr/lib/gstreamer-0.10/libgstffmpeg.so)
	@$(call install_copy, gst-ffmpeg, 0, 0, 0644, -, \
		/usr/lib/gstreamer-0.10/libgstpostproc.so)

	@$(call install_finish, gst-ffmpeg)

	@$(call touch)

# vim: syntax=make
