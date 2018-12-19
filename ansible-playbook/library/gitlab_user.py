#!/usr/bin/python
# (c) 2015, Werner Dijkerman (ikben@werner-dijkerman.nl)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type


ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}


DOCUMENTATION = '''
---
module: gitlab_user
short_description: Creates/updates/deletes Gitlab Users
description:
   - When the user does not exist in Gitlab, it will be created.
   - When the user does exists and state=absent, the user will be deleted.
   - When changes are made to user, the user will be updated.
version_added: "2.1"
author: "Werner Dijkerman (@dj-wasabi)"
requirements:
    - pyapi-gitlab python module
    - administrator rights on the Gitlab server
options:
    server_url:
        description:
            - Url of Gitlab server, with protocol (http or https).
        required: true
    validate_certs:
        description:
            - When using https if SSL certificate needs to be verified.
        type: bool
        default: 'yes'
        aliases:
            - validate_certs
    login_user:
        description:
            - Gitlab user name.
    login_password:
        description:
            - Gitlab password for login_user
    login_token:
        description:
            - Gitlab token for logging in.
    name:
        description:
            - Name of the user you want to create
        required: true
    username:
        description:
            - The username of the user.
        required: true
    password:
        description:
            - The password of the user.
            - GitLab server enforces minimum password length to 8, set this value with 8 or more characters.
        required: true
    email:
        description:
            - The email that belongs to the user.
        required: true
    sshkey_name:
        description:
            - The name of the sshkey
    sshkey_file:
        description:
            - The ssh key itself.
    group:
        description:
            - Add user as an member to this group.
    access_level:
        description:
            - The access level to the group. One of the following can be used.
            - guest
            - reporter
            - developer
            - master
            - owner
    state:
        description:
            - create or delete group.
            - Possible values are present and absent.
        default: present
        choices: ["present", "absent"]
    confirm:
        description:
            - Require confirmation.
        type: bool
        default: 'yes'
        version_added: "2.4"
'''

EXAMPLES = '''
- name: Delete Gitlab User
  gitlab_user:
    server_url: http://gitlab.example.com
    validate_certs: False
    login_token: WnUzDsxjy8230-Dy_k
    username: myusername
    state: absent
  delegate_to: localhost

- name: Create Gitlab User
  gitlab_user:
    server_url: https://gitlab.dj-wasabi.local
    validate_certs: True
    login_user: dj-wasabi
    login_password: MySecretPassword
    name: My Name
    username: myusername
    password: mysecretpassword
    email: me@example.com
    sshkey_name: MySSH
    sshkey_file: ssh-rsa AAAAB3NzaC1yc...
    state: present
  delegate_to: localhost
'''

RETURN = '''# '''

try:
    import gitlab
    HAS_GITLAB_PACKAGE = True
except:
    HAS_GITLAB_PACKAGE = False

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils._text import to_native


class GitLabUser(object):
    def __init__(self, module, git):
        self._module = module
        self._gitlab = git
        self.userObject = None
        self.groupObject = None

    def addToGroup(self, group, access_level):
        member_changed = False

        if access_level == "guest":
            level = gitlab.GUEST_ACCESS
        elif access_level == "reporter":
            level = gitlab.REPORTER_ACCESS
        elif access_level == "developer":
            level = gitlab.DEVELOPER_ACCESS
        elif access_level == "master":
            level = gitlab.MASTER_ACCESS
        elif access_level == "owner":
            level = gitlab.OWNER_ACCESS

        member_attributes = {
            "user_id": self.userObject.id,
            "access_level": level
        }

        member = None
        try:
            member = group.members.get(self.userObject.id)
        except gitlab.GitlabGetError as e:
            member = None
            member_changed = True

        if member:
            if member.access_level != level:
                member_changed = True
        else:
            if self._module.check_mode:
                self._module.exit_json(changed=True, result="User group membership would be updated.")

        if member_changed:
            if self._module.check_mode:
                self._module.exit_json(changed=True, result="User group membership would be updated.")
            if member:
                member.save()
            else:
                group.members.create(member_attributes)

        return member_changed

    def checkPasswordChange(self, user_password):
        """Check if password for user is to be changed, by attempting to acquire an oauth token"""
        password_change = False

        post_data = {"grant_type": "password", "username": self.userObject.username, "password": user_password}

        try:
            res = self._gitlab.http_post(self._gitlab.url + "/oauth/token", post_data=post_data)
            if res.ok:
                password_change = False
        except gitlab.GitlabAuthenticationError as e:
            password_change = True

    def createUser(self, user_name, user_username, user_password, user_email, user_sshkey_name, user_sshkey_file, group_name, access_level, confirm):
        user_changed = False
        arguments = {"name": user_name,
                     "username": user_username,
                     "email": user_email,
                     "password": user_password}

        sshkey_arguments = {"title": user_sshkey_name,
                            "key": user_sshkey_file}

        if self._module.check_mode:
            self._module.exit_json(changed=True)

        # Create the user
        try:
            self.userObject = self._gitlab.users.create(arguments)
            self.userObject.keys.create(sshkey_arguments)
            if self.existsGroup(group_name):
                self.addToGroup(self.groupObject, access_level)
            user_changed = True
        except Exception as e:
            self._module.fail_json(msg="Failed to create a user: %s " % e)

        return user_changed

    def deleteUser(self, user_username):
        user = self.userObject

        if self._module.check_mode:
            self._module.exit_json(changed=True)

        try:
            user.delete()
        except Exception as e:
            module.fail_json(msg='Failed to delete a user: %s' % e)
        return True

    def existsGroup(self, group_name):
        """When group exists, object will be stored in self.groupObject."""
        groups = self._gitlab.groups.list(search=group_name)
        if len(groups) == 1:
            self.groupObject = groups[0]
            return True

    def existsUser(self, username):
        """When user exists, object will be stored in self.userObject."""
        users = self._gitlab.users.list(search=username)
        if len(users) == 1:
            self.userObject = users[0]
            return True

    def updateUser(self, user_name, user_username, user_password, user_email, user_sshkey_name, user_sshkey_file, group_name, access_level, confirm):
        user_changed = False
        key_changed = False
        group_changed = False

        arguments = {"name": user_name,
                     "username": user_username,
                     "email": user_email}

        sshkey_arguments = {"title": user_sshkey_name,
                            "key": user_sshkey_file}

        # Check if we need to update the user attributes
        for arg_key, arg_value in arguments.items():
            if self.userObject.attributes[arg_key] != arg_value:
                self.userObject.attributes[arg_key] = arg_value
                user_changed = True

        # Check if user's password should change
        if self.checkPasswordChange(user_password):
            user_changed = True
            arguments.update(password=user_password)

        if user_changed:
            if self._module.check_mode:
                self._module.exit_json(changed=True, result="User should have updated.")
            self._gitlab.users.update(self.userObject.id, arguments)

        key_found = False
        # Check if we need to update the user's keys
        for user_key in self.userObject.keys.list():
            if user_key.title == user_sshkey_name:
                key_found = user_key
                if user_key.key != user_sshkey_file:
                    key_changed = True
                break

        if not key_found:
            key_changed = True

        if key_changed:
            if self._module.check_mode:
                self._module.exit_json(changed=True, result="User should have updated.")

            if key_found:
                key_found.delete()
            self.userObject.keys.create(sshkey_arguments)

        # Check if we need to update the user's group membership
        if self.existsGroup(group_name):
            group_changed = self.addToGroup(self.groupObject, access_level)

        # True if user attributes, keys, or group membership changed
        return user_changed or key_changed or group_changed


def main():
    global user_id
    module = AnsibleModule(
        argument_spec=dict(
            server_url=dict(required=True),
            validate_certs=dict(required=False, default=True, type='bool', aliases=['validate_certs']),
            login_user=dict(required=False, no_log=True),
            login_password=dict(required=False, no_log=True),
            login_token=dict(required=False, no_log=True),
            name=dict(required=True),
            username=dict(required=True),
            password=dict(required=True, no_log=True),
            email=dict(required=True),
            sshkey_name=dict(required=False),
            sshkey_file=dict(required=False),
            group=dict(required=False),
            access_level=dict(required=False, choices=["guest", "reporter", "developer", "master", "owner"]),
            state=dict(default="present", choices=["present", "absent"]),
            confirm=dict(required=False, default=True, type='bool')
        ),
        mutually_exclusive=[
            ['login_user', 'login_token'],
            ['login_password', 'login_token']
        ],
        required_together=[
            ['login_user', 'login_password']
        ],
        required_one_of=[
            ['login_user', 'login_token']
        ],
        supports_check_mode=True
    )

    if not HAS_GITLAB_PACKAGE:
        module.fail_json(msg="Missing required gitlab module (check docs or install with: pip install python-gitlab")

    server_url = module.params['server_url']
    validate_certs = module.params['validate_certs']
    login_user = module.params['login_user']
    login_password = module.params['login_password']
    login_token = module.params['login_token']
    user_name = module.params['name']
    user_username = module.params['username']
    user_password = module.params['password']
    user_email = module.params['email']
    user_sshkey_name = module.params['sshkey_name']
    user_sshkey_file = module.params['sshkey_file']
    group_name = module.params['group']
    access_level = module.params['access_level']
    state = module.params['state']
    confirm = module.params['confirm']

    if len(user_password) < 8:
        module.fail_json(msg="New user's 'password' should contain more than 8 characters.")

    # Gitlab > 10.2 does not support user/password authentication, so we need to get a token from oauth2
    if user_name:
        oauth_data = {"grant_type": "password", "username": login_user, "password": login_password}
        git = gitlab.Gitlab(url=server_url, api_version='4')
        res = git.http_post(git.url + "/oauth/token", post_data=oauth_data)

        import json
        access_token = json.loads(res.content)['access_token']

    # Check if vars are none
    if user_sshkey_file is not None and user_sshkey_name is not None:
        use_sshkey = True
    else:
        use_sshkey = False

    if group_name is not None and access_level is not None:
        add_to_group = True
        group_name = group_name.lower()
    else:
        add_to_group = False

    # Lets make an connection to the Gitlab server_url, with either login_user and login_password
    # or with login_token
    try:
        git = gitlab.Gitlab(url=server_url, ssl_verify=validate_certs, private_token=login_token,
                            oauth_token=access_token, api_version=4)
        git.auth()
    except (gitlab.exceptions.GitlabAuthenticationError, gitlab.exceptions.GitlabGetError) as e:
        module.fail_json(msg='Failed to connect to Gitlab server: %s' % to_native(e))

    # Validate if group exists and take action based on "state"
    user = GitLabUser(module, git)
    user_username = user_username.lower()
    user_exists = user.existsUser(user_username)

    if user_exists:
        if state == "absent":
            if user.deleteUser():
                module.exit_json(changed=True, result="Successfully deleted user %s" % user_username)
        else:
            if user.updateUser(user_name, user_username, user_password, user_email, user_sshkey_name, user_sshkey_file, group_name, access_level, confirm):
                module.exit_json(changed=True, result="Successfully updated the user %s" % user_username)
            else:
                module.exit_json(changed=False, result="No need to update the user %s" % user_username)
    else:
        if state == "absent":
            module.exit_json(changed=False, result="User deleted or does not exists")
        else:
            if user.createUser(user_name, user_username, user_password, user_email, user_sshkey_name, user_sshkey_file, group_name, access_level, confirm):
                module.exit_json(changed=True, result="Successfully created the user %s" % user_username)


if __name__ == '__main__':
    main()
