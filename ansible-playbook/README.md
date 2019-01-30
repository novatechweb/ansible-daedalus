# ansible-virtd-docker-mariadb-bacula-nginx


## Prerequesets:
### public_keys
The public key for the machine running the Ansible playbook needs to be in './public_keys'. The bootstrap.yml playbook installs all the public keys for the ansibleremote user.


### personal_credentials
The directory './personal_credentials/svn/' needs to have two files.
  - username:  Stores the ssh user to use to login the remote support-sight ssh server
  - password:  Stores the ssh password to use to login the remote support-sight ssh server


### credentials
The credentials directory will be recreated if it dose not exist. This is the desired result for a restore or a new bringup. If you wish to run the playbook on an already existing install then these files are needed localy. The current passwords would be found on the server in the '/etc/ansible-credentials/' directory. copy the entire directory structure from the remote server into your local './credentials/' folder. Make certain to change the permissions so the files are readable localy.


## Recovery:
The machines (daedalus and testdaedalus) are loaded using a kickstart script. These kickstart scripts need to be available to the CentOS 7.1 CD. So far this has been done by using another machine as a web server. Then next step is to boot the CentOS CD and interrupt the Grub boot sequence. Then you add a new kernel argument. Boot the CD with that argument and the machine will install CentOS.

This is an example of the kernel argument added to run the kickstart script:
> ks=http://172.16.64.3/~georgem/ks-centos7-testdaedalus.cfg

Once the machine has been loaded the script in this git repository can be used.
Use the bringup.sh script to first set up the ansibleremote user and then setup all the software.


## usefull commands for debugging the Ansible scripts:

Test the before_backup.sh script:
> sudo -HEu bacula /usr/libexec/bacula/before_backup ; echo $?

Test the after_backup.sh script:
> sudo -HEu bacula /usr/libexec/bacula/after_backup ; echo $?

Check for selinux policy changes:
> sudo audit2allow -abm baculavirt

