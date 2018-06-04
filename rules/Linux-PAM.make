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
PACKAGES-$(PTXCONF_LINUX_PAM) += linux-pam

#
# Paths and names
#
LINUX_PAM_VERSION	:= 1.1.3
LINUX_PAM_MD5		:= 9a977619848cfed372d9b361e328ec99
LINUX_PAM		:= Linux-PAM-$(LINUX_PAM_VERSION)
LINUX_PAM_SUFFIX	:= tar.gz
LINUX_PAM_URL		:= http://www.kernel.org/pub/linux/libs/pam/library/$(LINUX_PAM).$(LINUX_PAM_SUFFIX)
LINUX_PAM_SOURCE	:= $(SRCDIR)/$(LINUX_PAM).$(LINUX_PAM_SUFFIX)
LINUX_PAM_DIR		:= $(BUILDDIR)/$(LINUX_PAM)
LINUX_PAM_LICENSE	:= GPLv2+

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

#
# autoconf
#
LINUX_PAM_CONF_TOOL	:= autoconf
LINUX_PAM_CONF_OPT	:= $(CROSS_AUTOCONF_USR) \
	--prefix=/ \
	--libdir=/lib \
	--includedir=/include/security

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/linux-pam.targetinstall:
	@$(call targetinfo)

	@$(call install_init, linux-pam)
	@$(call install_fixup, linux-pam,PRIORITY,optional)
	@$(call install_fixup, linux-pam,SECTION,base)
	@$(call install_fixup, linux-pam,AUTHOR,"Joseph <Joseph.Lutz@novatechweb.com>")
	@$(call install_fixup, linux-pam,DESCRIPTION,missing)

	@$(call install_lib, linux-pam, 0, 0, 0644, libpam)
	@$(call install_lib, linux-pam, 0, 0, 0644, libpamc)
	@$(call install_lib, linux-pam, 0, 0, 0644, libpam_misc)

ifdef PTXCONF_LINUX_PAM_CONFIG_DIR
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/pam.d/other)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/pam.d/common-account)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/pam.d/common-auth)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/pam.d/common-password)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/pam.d/common-session)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/pam.d/common-auth-pam_tally)
endif

ifdef LINUX_PAM_CONFIG_FILE
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/pam.conf)
endif

ifdef PTXCONF_LINUX_PAM_ACCESS
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_access.so)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/security/access.conf)
endif
ifdef PTXCONF_LINUX_PAM_CRACKLIB
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_cracklib.so)
endif
ifdef PTXCONF_LINUX_PAM_DEBUG
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_debug.so)
endif
ifdef PTXCONF_LINUX_PAM_DENY
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_deny.so)
endif
ifdef PTXCONF_LINUX_PAM_ECHO
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_echo.so)
endif
ifdef PTXCONF_LINUX_PAM_ENV
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_env.so)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/security/pam_env.conf)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/environment)
endif
ifdef PTXCONF_LINUX_PAM_EXEC
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_exec.so)
endif
ifdef PTXCONF_LINUX_PAM_FAILDELAY
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_faildelay.so)
endif
ifdef PTXCONF_LINUX_PAM_FILTER
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_filter.so)
ifdef PTXCONF_LINUX_PAM_FILTER_UPPERLOWER
	@$(call install_copy, linux-pam, 0, 0, 0755, -, /lib/security/pam_filter/upperLOWER)
endif
endif
ifdef PTXCONF_LINUX_PAM_FTP
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_ftp.so)
endif
ifdef PTXCONF_LINUX_PAM_GROUP
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_group.so)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/security/group.conf)
endif
ifdef PTXCONF_LINUX_PAM_ISSUE
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_issue.so)
endif
ifdef PTXCONF_LINUX_PAM_KEYINIT
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_keyinit.so)
endif
ifdef PTXCONF_LINUX_PAM_LASTLOG
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_lastlog.so)
endif
ifdef PTXCONF_LINUX_PAM_LIMITS
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_limits.so)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/security/limits.conf)
endif
ifdef PTXCONF_LINUX_PAM_LISTFILE
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_listfile.so)
endif
ifdef PTXCONF_LINUX_PAM_LOCALUSER
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_localuser.so)
endif
ifdef PTXCONF_LINUX_PAM_LOGINUID
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_loginuid.so)
endif
ifdef PTXCONF_LINUX_PAM_MAIL
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_mail.so)
endif
ifdef PTXCONF_LINUX_PAM_MKHOMEDIR
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_mkhomedir.so)
ifdef PTXCONF_LINUX_PAM_MKHOMEDIR_MKHOMEDIR_HELPER
	@$(call install_copy, linux-pam, 0, 0, 0755, -, /sbin/mkhomedir_helper)
endif
endif
ifdef PTXCONF_LINUX_PAM_MOTD
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_motd.so)
endif
ifdef PTXCONF_LINUX_PAM_NAMESPACE
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_namespace.so)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/security/namespace.conf)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/security/namespace.init)
endif
ifdef PTXCONF_LINUX_PAM_NOLOGIN
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_nologin.so)
endif
ifdef PTXCONF_LINUX_PAM_PERMIT
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_permit.so)
endif
ifdef PTXCONF_LINUX_PAM_PWHISTORY
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_pwhistory.so)
endif
ifdef PTXCONF_LINUX_PAM_RHOST
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_rhosts.so)
endif
ifdef PTXCONF_LINUX_PAM_ROOTOK
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_rootok.so)
endif
ifdef PTXCONF_LINUX_PAM_SECURETTY
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_securetty.so)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/securetty)
endif
ifdef PTXCONF_LINUX_PAM_SELINUX
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_selinux.so)
endif
ifdef PTXCONF_LINUX_PAM_SHELLS
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_shells.so)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/shells)
endif
ifdef PTXCONF_LINUX_PAM_SUCCEED_IF
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_succeed_if.so)
endif
ifdef PTXCONF_LINUX_PAM_TALLY
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_tally.so)
ifdef PTXCONF_LINUX_PAM_TALLY_PAM_TALLY
	@$(call install_copy, linux-pam, 0, 0, 0755, -, /sbin/pam_tally)
endif
endif
ifdef PTXCONF_LINUX_PAM_TALLY2
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_tally2.so)
ifdef PTXCONF_LINUX_PAM_TALLY2_PAM_TALLY2
	@$(call install_copy, linux-pam, 0, 0, 0755, -, /sbin/pam_tally2)
endif
endif
ifdef PTXCONF_LINUX_PAM_TIME
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_time.so)
	@$(call install_alternative, linux-pam, 0, 0, 0644, /etc/security/time.conf)
endif
ifdef PTXCONF_LINUX_PAM_TIMESTAMP
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_timestamp.so)
ifdef PTXCONF_LINUX_PAM_TIMESTAMP_TIMESTAMP_CHECK
	@$(call install_copy, linux-pam, 0, 0, 0755, -, /sbin/pam_timestamp_check)
endif
endif
ifdef PTXCONF_LINUX_PAM_UMASK
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_umask.so)
endif
ifdef PTXCONF_LINUX_PAM_UNIX
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_unix.so)
ifdef PTXCONF_LINUX_PAM_UNIX_UNIX_UPDATE
	@$(call install_copy, linux-pam, 0, 0, 0755, -, /sbin/unix_update)
endif
ifdef PTXCONF_LINUX_PAM_UNIX_UNIX_CHKPWD
	@$(call install_copy, linux-pam, 0, 0, 4755, -, /sbin/unix_chkpwd)
endif
endif
ifdef PTXCONF_LINUX_PAM_USERDB
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_userdb.so)
endif
ifdef PTXCONF_LINUX_PAM_WARN
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_warn.so)
endif
ifdef PTXCONF_LINUX_PAM_WHEEL
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_wheel.so)
endif
ifdef PTXCONF_LINUX_PAM_XAUTH
	@$(call install_copy, linux-pam, 0, 0, 0644, -, /lib/security/pam_xauth.so)
endif

	@$(call install_finish, linux-pam)

	@$(call touch)

# vim: syntax=make
