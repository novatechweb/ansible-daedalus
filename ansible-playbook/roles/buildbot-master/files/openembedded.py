# -*- python -*-
# ex: set syntax=python:

# This is a sample buildmaster config file. It must be installed as
# 'master.cfg' in your buildmaster's base directory.

import os
from buildbot.plugins import secrets, steps, util

# This is the dictionary that the buildmaster pays attention to. We also use
# a shorter alias to save typing.
c = BuildmasterConfig = {}

setup_scripts_repourl = 'git@git.novatech-llc.com:ntel/setup-scripts.git'
custom_setup_scripts_repourl = 'git@git.novatech-llc.com:george.mccollister/setup-scripts.git'

LONG_RUN_TIMEOUT=14400

####### BUILDSLAVES

# The 'slaves' list defines the set of recognized buildslaves. Each element is
# a BuildSlave object, specifying a unique slave name and password.  The same
# slave name and password must be configured on the slave.
from buildbot.buildslave import BuildSlave
c['slaves'] = [
    BuildSlave("example-slave", "pass", max_builds=4),
]

####### CHANGESOURCES

# the 'change_source' setting tells the buildmaster how it should find out
# about source code changes.  Here we point to the buildbot clone of pyflakes.

def split_orion_file_branches(path):
    # turn "trunk/subdir/file.c" into (None, "subdir/file.c")
    # and "trunk/subdir/" into (None, "subdir/")
    # and "trunk/" into (None, "")
    # and "branches/1.5.x/subdir/file.c" into ("branches/1.5.x", "subdir/file.c")
    # and "branches/1.5.x/subdir/" into ("branches/1.5.x", "subdir/")
    # and "branches/1.5.x/" into ("branches/1.5.x", "")
    pieces = path.split('/')
    if len(pieces) > 1 and pieces[0] == 'current':
        return (None, '/'.join(pieces[1:]))
    elif len(pieces) > 2 and pieces[0] == 'branches':
        return ('/'.join(pieces[0:2]), '/'.join(pieces[2:]))
    else:
        return None

def split_file_projects_branches(path):
    # turn projectname/trunk/subdir/file.c into dict(project=projectname, branch=trunk, path=subdir/file.c)
    if not "/" in path:
        return None
    project, path = path.split("/", 1)
    f = split_orion_file_branches(path)
    if f:
        info = dict(project=project, path=f[1])
        if f[0]:
            info['branch'] = f[0]
        return info
    return f

from buildbot.changes.gitpoller import GitPoller
c['change_source'] = []
c['change_source'].append(GitPoller(
        repourl=setup_scripts_repourl,
	branches=['master'],
	project='ntel'))

####### SCHEDULERS

# Configure the Schedulers, which decide how to react to incoming changes.  In this
# case, just kick off a 'build' build

from buildbot.schedulers.basic import SingleBranchScheduler
from buildbot.schedulers import triggerable, timed
from buildbot.schedulers.forcesched import ForceScheduler
from buildbot.changes import filter
c['schedulers'] = []

## - Uncomment following to enabled automatic builds on workspace commit
#c['schedulers'].append(SingleBranchScheduler(
#                            name="current",
#                            change_filter=filter.ChangeFilter(branch=None),
#                            treeStableTimer=9*60,
#                            builderNames=["current_armeb_xscale","current_i686", "current_am335x"]))

#c['schedulers'].append(SingleBranchScheduler(
#                            name="linux-3.2",
#                            change_filter=filter.ChangeFilter(branch='branches/linux-3.2'),
#                            treeStableTimer=9*60,
#                            builderNames=["linux-3.2_armeb_xscale","linux-3.2_i686"]))
#c['schedulers'].append(SingleBranchScheduler(
#                            name="linux-3.8",
#                            change_filter=filter.ChangeFilter(branch='branches/linux-3.8'),
#                            treeStableTimer=9*60,
#                            builderNames=["linux-3.8_am335x"]))
c['schedulers'].append(ForceScheduler(
                            name="force",
                            builderNames=[ \
"ntel_master_orionlxm","ntel_morty_orionlxm", \
"ntel_master_orion_io","ntel_morty_orion_io", \
"ntel_master_orionlx_cpx","ntel_morty_orionlx_cpx", \
"ntel_master_qemux86_64","ntel_morty_qemux86_64", \
"ntel_master_orionlx_plus","ntel_morty_orionlx_plus"]))

c['schedulers'].append(timed.Nightly(
                            name="other-nightly",
                            branch=None,
                            builderNames=[ \
"ntel_morty_orionlxm", \
"ntel_morty_orion_io", \
"ntel_morty_orionlx_cpx", \
"ntel_morty_qemux86_64", \
"ntel_morty_orionlx_plus"],
                            hour=22))

####### BUILDERS

# The 'builders' list defines the Builders, which tell Buildbot how to perform a build:
# what steps, and which slaves can execute them.  Note that any particular build will
# only take place on one slave.

from buildbot.process.factory import BuildFactory
from buildbot.steps.source.git import Git
from buildbot.steps.shell import ShellCommand
from buildbot.steps import trigger
from buildbot.process.buildstep import LogLineObserver
from buildbot import locks


git_lock = locks.MasterLock("git")

class EnvStep(ShellCommand):
    def __init__(self, command='', **kwargs):
        kwargs['command'] = [
            'bash', '-c', 'source environment-ntel; %s' % command
        ]
        ShellCommand.__init__(self, **kwargs)

class initramfs_bundle_Step(ShellCommand):
    def __init__(self, image, **kwargs):
        kwargs['command'] = [
            'bash', '-c', 'echo "INITRAMFS_IMAGE = \\"%s\\"\nINITRAMFS_IMAGE_BUNDLE = \\"1\\"" >> conf/local.conf' % (image)
        ]
        ShellCommand.__init__(self, **kwargs)

class initramfs_Step(ShellCommand):
    def __init__(self, image, **kwargs):
        kwargs['command'] = [
            'bash', '-c', 'echo "INITRAMFS_IMAGE = \\"%s\\"" >> conf/local.conf' % (image)
        ]
        ShellCommand.__init__(self, **kwargs)

class rm_old_image_Step(ShellCommand):
    def __init__(self, **kwargs):
        kwargs['command'] = [
            'bash', '-c', 'echo "RM_OLD_IMAGE = \\"1\\"" >> conf/local.conf'
        ]
        ShellCommand.__init__(self, **kwargs)

### ntel_master_orionlxm ###
ntel_master_orionlxm_factory = BuildFactory()
# check out the source
ntel_master_orionlxm_factory.addStep(Git(repourl=setup_scripts_repourl, branch='master', mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
ntel_master_orionlxm_factory.addStep(initramfs_Step(image='overlay-ima-initramfs-image'))
ntel_master_orionlxm_factory.addStep(rm_old_image_Step())
ntel_master_orionlxm_factory.addStep(ShellCommand(command=["mkdir", "-p", "../mirror/premirrors", "../mirror/mirrors", "../mirror/sstate"]))
ntel_master_orionlxm_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/premirrors", "./mirror/"]))
ntel_master_orionlxm_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/mirrors", "./mirror/"]))
ntel_master_orionlxm_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/sstate", "./mirror/"]))
ntel_master_orionlxm_factory.addStep(ShellCommand(env={'MACHINE': 'orionlxm'}, command=["./oebb.sh", "config", "orionlxm"]))
ntel_master_orionlxm_factory.addStep(EnvStep(command="bitbake -k core-image-minimal"))
ntel_master_orionlxm_factory.addStep(EnvStep(command="bitbake -k orion-minimal-image"))
ntel_master_orionlxm_factory.addStep(EnvStep(command="bitbake -k orion-headless-image"))

### ntel_morty_orionlxm ###
ntel_morty_orionlxm_factory = BuildFactory()
# check out the source
ntel_morty_orionlxm_factory.addStep(Git(repourl=setup_scripts_repourl, branch='morty', mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
ntel_morty_orionlxm_factory.addStep(initramfs_Step(image='overlay-ima-initramfs-image'))
ntel_morty_orionlxm_factory.addStep(rm_old_image_Step())
ntel_morty_orionlxm_factory.addStep(ShellCommand(command=["mkdir", "-p", "../mirror/premirrors", "../mirror/mirrors", "../mirror/sstate"]))
ntel_morty_orionlxm_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/premirrors", "./mirror/"]))
ntel_morty_orionlxm_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/mirrors", "./mirror/"]))
ntel_morty_orionlxm_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/sstate", "./mirror/"]))
ntel_morty_orionlxm_factory.addStep(ShellCommand(env={'MACHINE': 'orionlxm'}, command=["./oebb.sh", "config", "orionlxm"]))
ntel_morty_orionlxm_factory.addStep(EnvStep(command="bitbake -k core-image-minimal"))
ntel_morty_orionlxm_factory.addStep(EnvStep(command="bitbake -k orion-minimal-image"))
ntel_morty_orionlxm_factory.addStep(EnvStep(command="bitbake -k orion-headless-image"))
ntel_morty_orionlxm_factory.addStep(EnvStep(command="bitbake orionlxm-fsfit"))
ntel_morty_orionlxm_factory.addStep(EnvStep(command="bitbake orionlxm-swu-image"))

### ntel_master_orion_io ###
ntel_master_orion_io_factory = BuildFactory()
# check out the source
ntel_master_orion_io_factory.addStep(Git(repourl=setup_scripts_repourl, branch='master', mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
ntel_master_orion_io_factory.addStep(initramfs_Step(image='overlay-ima-initramfs-image'))
ntel_master_orion_io_factory.addStep(rm_old_image_Step())
ntel_master_orion_io_factory.addStep(ShellCommand(command=["mkdir", "-p", "../mirror/premirrors", "../mirror/mirrors", "../mirror/sstate"]))
ntel_master_orion_io_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/premirrors", "./mirror/"]))
ntel_master_orion_io_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/mirrors", "./mirror/"]))
ntel_master_orion_io_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/sstate", "./mirror/"]))
ntel_master_orion_io_factory.addStep(ShellCommand(env={'MACHINE': 'orion-io'}, command=["./oebb.sh", "config", "orion-io"]))
ntel_master_orion_io_factory.addStep(EnvStep(command="bitbake -k core-image-minimal"))
ntel_master_orion_io_factory.addStep(EnvStep(command="bitbake -k orion-minimal-image"))
ntel_master_orion_io_factory.addStep(EnvStep(command="bitbake -k orion-headless-image"))

### ntel_morty_orion_io ###
ntel_morty_orion_io_factory = BuildFactory()
# check out the source
ntel_morty_orion_io_factory.addStep(Git(repourl=setup_scripts_repourl, branch='morty', mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
ntel_morty_orion_io_factory.addStep(initramfs_Step(image='overlay-ima-initramfs-image'))
ntel_morty_orion_io_factory.addStep(rm_old_image_Step())
ntel_morty_orion_io_factory.addStep(ShellCommand(command=["mkdir", "-p", "../mirror/premirrors", "../mirror/mirrors", "../mirror/sstate"]))
ntel_morty_orion_io_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/premirrors", "./mirror/"]))
ntel_morty_orion_io_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/mirrors", "./mirror/"]))
ntel_morty_orion_io_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/sstate", "./mirror/"]))
ntel_morty_orion_io_factory.addStep(ShellCommand(env={'MACHINE': 'orion-io'}, command=["./oebb.sh", "config", "orion-io"]))
ntel_morty_orion_io_factory.addStep(EnvStep(command="bitbake -k core-image-minimal"))
ntel_morty_orion_io_factory.addStep(EnvStep(command="bitbake -k orion-minimal-image"))
ntel_morty_orion_io_factory.addStep(EnvStep(command="bitbake -k orion-headless-image"))
ntel_morty_orion_io_factory.addStep(EnvStep(command="bitbake orion-io-fsfit"))
ntel_morty_orion_io_factory.addStep(EnvStep(command="bitbake orion-io-swu-image"))

### ntel_master_orionlx_cpx ###
ntel_master_orionlx_cpx_factory = BuildFactory()
# check out the source
ntel_master_orionlx_cpx_factory.addStep(Git(repourl=setup_scripts_repourl, branch='master', mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
ntel_master_orionlx_cpx_factory.addStep(initramfs_bundle_Step(image='overlay-ima-initramfs-image'))
ntel_master_orionlx_cpx_factory.addStep(rm_old_image_Step())
ntel_master_orionlx_cpx_factory.addStep(ShellCommand(command=["mkdir", "-p", "../mirror/premirrors", "../mirror/mirrors", "../mirror/sstate"]))
ntel_master_orionlx_cpx_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/premirrors", "./mirror/"]))
ntel_master_orionlx_cpx_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/mirrors", "./mirror/"]))
ntel_master_orionlx_cpx_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/sstate", "./mirror/"]))
ntel_master_orionlx_cpx_factory.addStep(ShellCommand(env={'MACHINE': 'orionlx-cpx'}, command=["./oebb.sh", "config", "orionlx-cpx"]))
ntel_master_orionlx_cpx_factory.addStep(EnvStep(command="bitbake -k core-image-minimal"))
ntel_master_orionlx_cpx_factory.addStep(EnvStep(command="bitbake -k orion-minimal-image"))
ntel_master_orionlx_cpx_factory.addStep(EnvStep(command="bitbake -k orion-headless-image"))
ntel_master_orionlx_cpx_factory.addStep(EnvStep(command="bitbake -k orion-graphical-image", timeout=LONG_RUN_TIMEOUT))

### ntel_morty_orionlx_cpx ###
ntel_morty_orionlx_cpx_factory = BuildFactory()
# check out the source
ntel_morty_orionlx_cpx_factory.addStep(Git(repourl=setup_scripts_repourl, branch='morty', mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
ntel_morty_orionlx_cpx_factory.addStep(initramfs_bundle_Step(image='overlay-ima-initramfs-image'))
ntel_morty_orionlx_cpx_factory.addStep(rm_old_image_Step())
ntel_morty_orionlx_cpx_factory.addStep(ShellCommand(command=["mkdir", "-p", "../mirror/premirrors", "../mirror/mirrors", "../mirror/sstate"]))
ntel_morty_orionlx_cpx_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/premirrors", "./mirror/"]))
ntel_morty_orionlx_cpx_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/mirrors", "./mirror/"]))
ntel_morty_orionlx_cpx_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/sstate", "./mirror/"]))
ntel_morty_orionlx_cpx_factory.addStep(ShellCommand(env={'MACHINE': 'orionlx-cpx'}, command=["./oebb.sh", "config", "orionlx-cpx"]))
ntel_morty_orionlx_cpx_factory.addStep(EnvStep(command="bitbake -k core-image-minimal"))
ntel_morty_orionlx_cpx_factory.addStep(EnvStep(command="bitbake -k orion-minimal-image"))
ntel_morty_orionlx_cpx_factory.addStep(EnvStep(command="bitbake -k orion-headless-image"))
ntel_morty_orionlx_cpx_factory.addStep(EnvStep(command="bitbake -k orion-graphical-image", timeout=LONG_RUN_TIMEOUT))
ntel_morty_orionlx_cpx_factory.addStep(EnvStep(command="bitbake orionlx-cpx-swu-image"))
ntel_morty_orionlx_cpx_factory.addStep(EnvStep(command="bitbake orionlx-cpx-disk-swu-image"))

### ntel_master_qemux86_64 ###
ntel_master_qemux86_64_factory = BuildFactory()
# check out the source
ntel_master_qemux86_64_factory.addStep(Git(repourl=setup_scripts_repourl, branch='master', mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
ntel_master_qemux86_64_factory.addStep(rm_old_image_Step())
ntel_master_qemux86_64_factory.addStep(ShellCommand(command=["mkdir", "-p", "../mirror/premirrors", "../mirror/mirrors", "../mirror/sstate"]))
ntel_master_qemux86_64_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/premirrors", "./mirror/"]))
ntel_master_qemux86_64_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/mirrors", "./mirror/"]))
ntel_master_qemux86_64_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/sstate", "./mirror/"]))
ntel_master_qemux86_64_factory.addStep(ShellCommand(env={'MACHINE': 'qemux86-64'}, command=["./oebb.sh", "config", "qemux86-64"]))
ntel_master_qemux86_64_factory.addStep(EnvStep(command="bitbake -k core-image-minimal"))
ntel_master_qemux86_64_factory.addStep(EnvStep(command="bitbake -k orion-minimal-image"))
ntel_master_qemux86_64_factory.addStep(EnvStep(command="bitbake -k orion-headless-image"))
ntel_master_qemux86_64_factory.addStep(EnvStep(command="bitbake -k orion-graphical-image", timeout=LONG_RUN_TIMEOUT))

### ntel_morty_qemux86_64 ###
ntel_morty_qemux86_64_factory = BuildFactory()
# check out the source
ntel_morty_qemux86_64_factory.addStep(Git(repourl=setup_scripts_repourl, branch='morty', mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
ntel_morty_qemux86_64_factory.addStep(rm_old_image_Step())
ntel_morty_qemux86_64_factory.addStep(ShellCommand(command=["mkdir", "-p", "../mirror/premirrors", "../mirror/mirrors", "../mirror/sstate"]))
ntel_morty_qemux86_64_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/premirrors", "./mirror/"]))
ntel_morty_qemux86_64_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/mirrors", "./mirror/"]))
ntel_morty_qemux86_64_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/sstate", "./mirror/"]))
ntel_morty_qemux86_64_factory.addStep(ShellCommand(env={'MACHINE': 'qemux86-64'}, command=["./oebb.sh", "config", "qemux86-64"]))
ntel_morty_qemux86_64_factory.addStep(EnvStep(command="bitbake -k core-image-minimal"))
ntel_morty_qemux86_64_factory.addStep(EnvStep(command="bitbake -k orion-minimal-image"))
ntel_morty_qemux86_64_factory.addStep(EnvStep(command="bitbake -k orion-headless-image"))
ntel_morty_qemux86_64_factory.addStep(EnvStep(command="bitbake -k orion-graphical-image", timeout=LONG_RUN_TIMEOUT))

### ntel_master_orionlx_plus ###
ntel_master_orionlx_plus_factory = BuildFactory()
# check out the source
ntel_master_orionlx_plus_factory.addStep(Git(repourl=setup_scripts_repourl, branch='master', mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
ntel_master_orionlx_plus_factory.addStep(initramfs_Step(image='overlay-ima-initramfs-image'))
ntel_master_orionlx_plus_factory.addStep(rm_old_image_Step())
ntel_master_orionlx_plus_factory.addStep(ShellCommand(command=["mkdir", "-p", "../mirror/premirrors", "../mirror/mirrors", "../mirror/sstate"]))
ntel_master_orionlx_plus_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/premirrors", "./mirror/"]))
ntel_master_orionlx_plus_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/mirrors", "./mirror/"]))
ntel_master_orionlx_plus_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/sstate", "./mirror/"]))
ntel_master_orionlx_plus_factory.addStep(ShellCommand(env={'MACHINE': 'orionlx-plus'}, command=["./oebb.sh", "config", "orionlx-plus"]))
ntel_master_orionlx_plus_factory.addStep(EnvStep(command="bitbake -k core-image-minimal"))
ntel_master_orionlx_plus_factory.addStep(EnvStep(command="bitbake -k orion-minimal-image"))
ntel_master_orionlx_plus_factory.addStep(EnvStep(command="bitbake -k orion-headless-image"))
ntel_master_orionlx_plus_factory.addStep(EnvStep(command="bitbake -k orion-graphical-image", timeout=LONG_RUN_TIMEOUT))

### ntel_morty_orionlx_plus ###
ntel_morty_orionlx_plus_factory = BuildFactory()
# check out the source
ntel_morty_orionlx_plus_factory.addStep(Git(repourl=setup_scripts_repourl, branch='morty', mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
ntel_morty_orionlx_plus_factory.addStep(initramfs_Step(image='overlay-ima-initramfs-image'))
ntel_morty_orionlx_plus_factory.addStep(rm_old_image_Step())
ntel_morty_orionlx_plus_factory.addStep(ShellCommand(command=["mkdir", "-p", "../mirror/premirrors", "../mirror/mirrors", "../mirror/sstate"]))
ntel_morty_orionlx_plus_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/premirrors", "./mirror/"]))
ntel_morty_orionlx_plus_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/mirrors", "./mirror/"]))
ntel_morty_orionlx_plus_factory.addStep(ShellCommand(command=["ln", "-s", "../../mirror/sstate", "./mirror/"]))
ntel_morty_orionlx_plus_factory.addStep(ShellCommand(env={'MACHINE': 'orionlx-plus'}, command=["./oebb.sh", "config", "orionlx-plus"]))
ntel_morty_orionlx_plus_factory.addStep(EnvStep(command="bitbake -k core-image-minimal"))
ntel_morty_orionlx_plus_factory.addStep(EnvStep(command="bitbake -k orion-minimal-image"))
ntel_morty_orionlx_plus_factory.addStep(EnvStep(command="bitbake -k orion-headless-image"))
ntel_morty_orionlx_plus_factory.addStep(EnvStep(command="bitbake -k orion-graphical-image", timeout=LONG_RUN_TIMEOUT))
ntel_morty_orionlx_plus_factory.addStep(EnvStep(command="bitbake orionlx-plus-fsfit"))
ntel_morty_orionlx_plus_factory.addStep(EnvStep(command="bitbake orionlx-plus-swu-image"))

from buildbot.config import BuilderConfig

c['builders'] = []
c['builders'].append(
    BuilderConfig(name="ntel_master_orionlxm",
      slavenames=["example-slave"],
      factory=ntel_master_orionlxm_factory))
c['builders'].append(
    BuilderConfig(name="ntel_morty_orionlxm",
      slavenames=["example-slave"],
      factory=ntel_morty_orionlxm_factory))
c['builders'].append(
    BuilderConfig(name="ntel_master_orion_io",
      slavenames=["example-slave"],
      factory=ntel_master_orion_io_factory))
c['builders'].append(
    BuilderConfig(name="ntel_morty_orion_io",
      slavenames=["example-slave"],
      factory=ntel_morty_orion_io_factory))
c['builders'].append(
    BuilderConfig(name="ntel_master_orionlx_cpx",
      slavenames=["example-slave"],
      factory=ntel_master_orionlx_cpx_factory))
c['builders'].append(
    BuilderConfig(name="ntel_morty_orionlx_cpx",
      slavenames=["example-slave"],
      factory=ntel_morty_orionlx_cpx_factory))
c['builders'].append(
    BuilderConfig(name="ntel_master_qemux86_64",
      slavenames=["example-slave"],
      factory=ntel_master_qemux86_64_factory))
c['builders'].append(
    BuilderConfig(name="ntel_morty_qemux86_64",
      slavenames=["example-slave"],
      factory=ntel_morty_qemux86_64_factory))
c['builders'].append(
    BuilderConfig(name="ntel_master_orionlx_plus",
      slavenames=["example-slave"],
      factory=ntel_master_orionlx_plus_factory))
c['builders'].append(
    BuilderConfig(name="ntel_morty_orionlx_plus",
      slavenames=["example-slave"],
      factory=ntel_morty_orionlx_plus_factory))
