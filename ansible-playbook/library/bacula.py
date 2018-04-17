#!/usr/bin/python
# -*- coding: utf-8 -*-

import pexpect
import re
import time

"""

Bacula Ansible module
"""

DOCUMENTATION = '''
---
module: bacula

short_description: Bacula Ansible module
description:
    - Bacula Ansible module to restore files
author: '"George McCollister" <george.mccollister@gmail.com>'
options:
    command:
        description:
            - command to run
    storage:
        description:
            - Bacula storage name to use
    fileset:
        description:
            - Bacula fileset to use
    path_to_restore:
        description:
            - Path that you want restored
    dest:
        description:
            - Restore to this location
'''

EXAMPLES = '''
#Restore example
- bacula: command=restore
          storage='TapeDrive'
          fileset='Full Set'
          path_to_restore='/var/lib/libvirt/backup/vm1'
          dest='/tmp/bacula-restores'
'''

def get_job_status(p, jobid):
    p.sendline('list jobs')
    p.expect('\|\s*%d \|[^\|]*\|[^\|]*\|[^\|]*\|[^\|]*\|[^\|]*\|[^\|]*\| (\w)\s*\|\r\n' % (jobid))
    return p.match.group(1)

def restore(module, storage, fileset, path_to_restore, dest):
    p = pexpect.spawn('/usr/sbin/bconsole -n')
    p.expect('\*')

    p.sendline('mount storage=%s' % (storage))
    p.expect('\*')

    p.sendline('restore where=%s' % (dest))

    p.expect('Select item:\s*\(1-13\):')

    p.sendline('5') #Select the most recent backup for a client

    p.expect('Select FileSet resource')

    fileset_option = None
    filesetre = re.compile('\s+(\d+): ([^\r]+)\r\n')
    for m in filesetre.finditer(p.before):
        if m.group(2) == fileset:
            fileset_option = m.group(1)
            break

    if not fileset_option:
        module.fail_json(msg="Can't find FileSet: %s" % (fileset))

    p.sendline(fileset_option)

    p.expect('\$ ')

    split_path = path_to_restore[1:].split('/')
    if len(split_path) > 1:
        for s in split_path[0:len(split_path)-1]:
            p.sendline("cd %s" % (s))
            p.expect('\$ ')

    p.sendline("mark %s" % (split_path[-1]))
    p.expect('\$ ')

    p.sendline('done')
    p.expect_exact('OK to run? (yes/mod/no):')

    p.sendline('yes')
    p.expect('Job queued\. JobId=(\d+)\r\n')

    jobid = int(p.match.group(1))

    # Sleep while the job is running
    while get_job_status(p, jobid) in ['R', 'C']:
        time.sleep(5)

    status = get_job_status(p, jobid)

    if status != 'T':
        module.fail_json(msg='Unexpected job status of: %s' % (status))

def main():
    module = AnsibleModule(
            argument_spec = dict(
                command=dict(default=None),
                storage=dict(default=None),
                fileset=dict(default=None),
                path_to_restore=dict(default=None),
                dest=dict(default=None),
                )
            )
    command = module.params["command"]
    storage = module.params["storage"]
    fileset = module.params["fileset"]
    path_to_restore = module.params["path_to_restore"]
    dest = module.params["dest"]

    if command == 'restore':
        restore(module, storage, fileset, path_to_restore, dest)
    else:
        module.fail_json(msg="Invalid command: %s" % (command))

    module.exit_json(msg="Finished %s" % (command), changed=True)

from ansible.module_utils.basic import *
main()
