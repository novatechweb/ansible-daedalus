jorti.mariadb
=========

MariaDB role for Fedora and CentOS >= 7

Role Variables
--------------
The default parameters are:

  * mariadb_server_config_dir: "/etc/my.cnf.d"
  * mariadb_client_config: "/root/.my.cnf"
  * mariadb_entropy_bits: 100
  * mariadb_open_firewall: false
  * mariadb_remote_root_access: false
  * mariadb_innodb_use_barracuda: true
  * mariadb_character_set: "utf8"
  * mariadb_collation: "utf8_general_ci"


Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: jorti.mariadb, mariadb_open_firewall: true, mariadb_remote_root_access: false }

License
-------

GPLv3

Author Information
------------------

https://miceliux.com/about/
