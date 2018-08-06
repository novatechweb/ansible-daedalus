import ldap
l = ldap.initialize('ldap://ldap.novatech-llc.com:389',trace_level=2)

l.simple_bind_s(who="cn=admin,dc=novatech",cred="7J1YaZvslJnCmkNXD.IJ")

l.search_s("ou=user,dc=novatech",ldap.SCOPE_SUBTREE,None,["uid"])

l.get_option(ldap.OPT_X_TLS)
l.get_option(ldap.OPT_X_TLS_ALLOW)
l.get_option(ldap.OPT_X_TLS_CACERTFILE)
l.get_option(ldap.OPT_X_TLS_CERTFILE)
l.get_option(ldap.OPT_X_TLS_KEYFILE)

l.search_s("cn=config",ldap.SCOPE_SUBTREE)
