#!/usr/bin/python
#
# Copyright 2016 Red Hat | Ansible
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type


ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}


DOCUMENTATION = '''
---
module: docker_health

short_description: Get health of Docker container

version_added: "2.5.0"

description:
     - Provide one container identifier, and the module will inspect it,
       returning a dictionary of health information.

options:
  name:
    description:
      - A container name or id, as you would pass to 'docker inspect'
    required: true

extends_documentation_fragment:
    - docker

requirements:
  - "python >= 2.6"
  - "docker-py >= 1.7.0"
  - "Docker API >= 1.20"

author:
  - Andrew Cooper (me@andrewcooper.me)

'''

EXAMPLES = '''

- name: Get health for a container
  docker_health:
    name: mycontainer

- name: Wait for a container to become healthy
  docker_health:
    name: mycontainer
    register: health
    retries: 5
    delay: 30
    until: health.Health.Status == "healthy"
'''

RETURN = '''
'''

try:
    from docker import utils
except ImportError:
    # missing docker-py handled in docker_common
    pass

from ansible.module_utils.docker_common import AnsibleDockerClient, DockerBaseClass


class ContainerManager(DockerBaseClass):

    def __init__(self, client):

        super(ContainerManager, self).__init__()

        self.client = client
        self.name = self.client.module.params.get('name')
        self.log("Gathering facts for images: %s" % (str(self.name)))

        self.results = self.get_state()

    def fail(self, msg):
        self.client.fail(msg)

    def get_state(self):
        '''
        Lookup and inspect the container name.

        :returns dictionary of state information
        '''

        inspection = self.client.inspect_container(self.name)
        state = inspection['State']
        if 'Health' not in state:
            state['Health'] = {
                'Status': 'starting',
                'Log': list(),
                'FailingStreak': 0
            }
            if state['Status'] == 'running':
                state['Health']['Status'] = 'healthy'

        state['changed'] = False
        state['failed'] = False
        return state


def main():
    argument_spec = dict(
        name=dict(type='str', required=True),

    )

    client = AnsibleDockerClient(
        argument_spec=argument_spec
    )

    cm = ContainerManager(client)
    client.module.exit_json(**cm.results)


if __name__ == '__main__':
    main()
