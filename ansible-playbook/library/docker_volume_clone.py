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
module: docker_volume_clone

short_description: Clone a docker volume

version_added: "2.5.0"

description:
     - Clones one docker named volume (or host directory)
       to another docker named volume (or host directory)

options:
  src:
    description:
      - A volume name or host directory
    required: true
  dest:
    description:
      - A volume name or host directory
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

- name: Clone one volume into another
  docker_volume_clone:
    src: volume1
    dest: volume2

- name: Mirror a host directory into a volume
  docker_volume_clone:
    src: /path/to/host/directory
    dest: volume2
'''

RETURN = '''
'''

try:
    import docker
    from docker import utils
except ImportError:
    # missing docker-py handled in docker_common
    pass

from ansible.module_utils.docker_common import AnsibleDockerClient, DockerBaseClass


class VolumeManager(DockerBaseClass):

    def __init__(self, client):

        super(VolumeManager, self).__init__()

        self.client = client
        self.hlclient = docker.DockerClient(**client._connect_params)

        self.src = self.client.module.params.get('src')
        self.dest = self.client.module.params.get('dest')
        self.log("Cloning volume %s to %s" % (self.src, self.dest))
        self.results = {}

        # self.create_rsync_image()
        self.clone_volume()

    def create_rsync_image(self):
        import StringIO
        dockerfile = StringIO.StringIO("""
            FROM alpine:latest
            RUN apk add --no-cache rsync
            ENTRYPOINT ["/usr/bin/rsync"]
            """)
        self.rsync = self.hlclient.images.build(
            fileobj=dockerfile,
            tag='ansibleutils/rsync:latest'
        )

    def clone_volume(self):
        cmd = "apk add --no-cache rsync && /usr/bin/rsync --archive --del /from/ /to/"
        stdout = ''
        try:
            stdout = self.hlclient.containers.run(
                image='alpine:latest',
                command=['/bin/ash', '-c', cmd],
                auto_remove=True,
                stdout=True,
                stderr=True,
                volumes={
                    self.src: {'bind': '/from', 'mode': 'ro'},
                    self.dest: {'bind': '/to', 'mode': 'rw'}
                }
            )
            self.results['rc'] = 0
            self.results['changed'] = True
        except (docker.errors.ContainerError,
                docker.errors.ImageNotFound,
                docker.errors.APIError) as err:
            self.results['rc'] = 1
            self.results['failed'] = True
            self.results['msg'] = str(err)
        finally:
            self.results['stdout'] = stdout


def main():
    argument_spec = dict(
        src=dict(type='str', required=True),
        dest=dict(type='str', required=True),
    )

    client = AnsibleDockerClient(
        argument_spec=argument_spec
    )

    cm = VolumeManager(client)
    client.module.exit_json(**cm.results)


if __name__ == '__main__':
    main()
