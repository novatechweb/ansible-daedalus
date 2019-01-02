# -*- python -*-
# ex: set syntax=python:

# This is a sample buildmaster config file. It must be installed as
# 'master.cfg' in your buildmaster's base directory.

import os
from buildbot.plugins import secrets, steps, util

# This is the dictionary that the buildmaster pays attention to. We also use
# a shorter alias to save typing.
c = BuildmasterConfig = {}

workspace_repourl = 'git@git.novatech-llc.com:Orion-ptxdist/workspace-ptxdist2.git'
setup_scripts_repourl = 'git@git.novatech-llc.com:ntel/setup-scripts.git'
custom_setup_scripts_repourl = 'git@git.novatech-llc.com:george.mccollister/setup-scripts.git'
acceptance_test_repourl = 'git@git.novatech-llc.com:NovaTech-Testing/AcceptanceTests.git'

LONG_RUN_TIMEOUT=14400

####### BUILDSLAVES

# The 'slaves' list defines the set of recognized buildslaves. Each element is
# a BuildSlave object, specifying a unique slave name and password.  The same
# slave name and password must be configured on the slave.
from buildbot.buildslave import BuildSlave
c['slaves'] = [
    BuildSlave("example-slave", "pass", max_builds=4),
    BuildSlave("orion-i686-slave", "pass"),
    BuildSlave("orion-armeb-xscale-slave", "pass"),
    BuildSlave("orion-am335x-slave", "pass"),
]

# 'slavePortnum' defines the TCP port to listen on for connections from slaves.
# This must match the value configured into the buildslaves (with their
# --master option)
c['slavePortnum'] = 9989

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
        repourl=workspace_repourl,
	branches=['master'],
	project='ptxdist'))
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
"current_armeb_xscale","current_i686","current_am335x", \
]))

c['schedulers'].append(timed.Nightly(
                            name="other-nightly",
                            branch=None,
                            builderNames=[ \
"current_armeb_xscale","current_i686","current_am335x", \
],
                            hour=22))

c['schedulers'].append(triggerable.Triggerable(
                            name="upgrade_i686",
                            builderNames=["upgrade_i686"]))

c['schedulers'].append(triggerable.Triggerable(
                            name="local_tests_i686",
                            builderNames=["local_tests_i686"]))

c['schedulers'].append(triggerable.Triggerable(
                            name="remote_tests_i686",
                            builderNames=["remote_tests_i686"]))

c['schedulers'].append(triggerable.Triggerable(
                            name="local_tests_armeb_xscale",
                            builderNames=["local_tests_armeb_xscale"]))

c['schedulers'].append(triggerable.Triggerable(
                            name="remote_tests_armeb_xscale",
                            builderNames=["remote_tests_armeb_xscale"]))

c['schedulers'].append(triggerable.Triggerable(
                            name="upgrade_am335x",
                            builderNames=["upgrade_am335x"]))

c['schedulers'].append(triggerable.Triggerable(
                            name="local_tests_am335x",
                            builderNames=["local_tests_am335x"]))

c['schedulers'].append(triggerable.Triggerable(
                            name="remote_tests_am335x",
                            builderNames=["remote_tests_am335x"]))

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

class PTXDistBuildCounter(LogLineObserver):
    numTargets = 0
    numPackages = 0
    def outLineReceived(self, line):
        if line.startswith('finished target '):
            self.numTargets += 1
            self.step.setProgress('targets', self.numTargets)
            if line.strip().endswith('.targetinstall'):
                self.numPackages += 1
                self.step.setProgress('packages', self.numPackages)


class PTXDistBuild(ShellCommand):
    def __init__(self, **kwargs):
        ShellCommand.__init__(self, **kwargs)   # always upcall!
        counter = PTXDistBuildCounter()
        self.addLogObserver('stdio', counter)
        self.progressMetrics += ('targets','packages')

git_lock = locks.MasterLock("git")

### current_armeb_xscale ###
current_armeb_xscale_factory = BuildFactory()
# check out the source
current_armeb_xscale_factory.addStep(Git(repourl=workspace_repourl, mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
current_armeb_xscale_factory.addStep(ShellCommand(command=["ptxdist", "platform", "armeb-xscale"]))
current_armeb_xscale_factory.addStep(ShellCommand(command=["ptxdist", "select", "OrionLX-armeb-xscale-glibc"]))
current_armeb_xscale_factory.addStep(PTXDistBuild(command=["ptxdist", "go"]))
current_armeb_xscale_factory.addStep(ShellCommand(command=["ptxdist", "make", "ipkg-push"]))
current_armeb_xscale_factory.addStep(ShellCommand(command=["./scripts/ipkg-header"]))
current_armeb_xscale_factory.addStep(ShellCommand(command=["ptxdist", "collection", "armeb-base"]))
current_armeb_xscale_factory.addStep(ShellCommand(command=["ptxdist", "images"]))
current_armeb_xscale_factory.addStep(ShellCommand(command=["cp", "platform-armeb-xscale/images/root.jffs2_64", "/srv/tftp/"]))
current_armeb_xscale_factory.addStep(ShellCommand(command=["cp", "platform-armeb-xscale/images/root.jffs2_128", "/srv/tftp/"]))
current_armeb_xscale_factory.addStep(ShellCommand(command=["./scripts/build-upgrade-test.sh"]))
current_armeb_xscale_factory.addStep(ShellCommand(command=["curl", "--progress-bar", "-o", "/dev/null", "http://george:1234@172.16.190.70/outlet?1=CCL"]))
current_armeb_xscale_factory.addStep(ShellCommand(command=[
	"./scripts/upgradetest.py",
	"load_7_upgrade_to_8",
	"/srv/tftp/root.jffs2_64",
	"/home/georgem/testrack0",
	"172.16.64.150",
	"--install-path", "172.16.64.3/~georgem/ipkg-repository/OrionLX-armeb-xscale-glibc/dists",
	"--packages",
	"buildbot-slave",
	"orionpythontests",
	"orionprotocoltests",
	"--orion-config", "./local-pkg/buildslave_config_armeb-xscale.tar.gz"]))
current_armeb_xscale_factory.addStep(trigger.Trigger(schedulerNames=['local_tests_armeb_xscale'], waitForFinish=True))
current_armeb_xscale_factory.addStep(trigger.Trigger(schedulerNames=['remote_tests_armeb_xscale'], waitForFinish=True))

### local_tests_armeb_xscale ###
local_tests_armeb_xscale_factory = BuildFactory()
local_tests_armeb_xscale_factory.addStep(ShellCommand(command=["uptime"]))
local_tests_armeb_xscale_factory.addStep(ShellCommand(command=["uname", "-a"]))
local_tests_armeb_xscale_factory.addStep(ShellCommand(command=["py.test"], workdir="/usr/local/OrionPythonTests"))

### remote_tests_armeb_xscale ###
remote_tests_armeb_xscale_factory = BuildFactory()
# check out the source
remote_tests_armeb_xscale_factory.addStep(Git(repourl=acceptance_test_repourl, alwaysUseLatest=True, mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(120, 5)))
remote_tests_armeb_xscale_factory.addStep(ShellCommand(command=["py.test", "-s", "--orion=172.16.64.150", "--hub-address=172.16.64.25:4444", "--browser=chrome"], workdir='build/WebUI'))

### current_i686 ###
current_i686_factory = BuildFactory()
# check out the source
current_i686_factory.addStep(Git(repourl=workspace_repourl, mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
current_i686_factory.addStep(ShellCommand(command=["ptxdist", "platform", "i686"]))
current_i686_factory.addStep(ShellCommand(command=["ptxdist", "select", "OrionLX-i686-glibc"]))
current_i686_factory.addStep(PTXDistBuild(command=["ptxdist", "go"]))
current_i686_factory.addStep(ShellCommand(command=["ptxdist", "make", "ipkg-push"]))
current_i686_factory.addStep(ShellCommand(command=["./scripts/ipkg-header"]))
current_i686_factory.addStep(ShellCommand(command=["ptxdist", "collection", "i686-base"]))
current_i686_factory.addStep(ShellCommand(command=["ptxdist", "images"]))
current_i686_factory.addStep(ShellCommand(command=["gzip", "platform-i686/images/hd.img"]))
current_i686_factory.addStep(ShellCommand(command=["cp", "platform-i686/images/hd.img.gz", "/home/georgem/public_html/"]))
current_i686_factory.addStep(trigger.Trigger(schedulerNames=['upgrade_i686'], waitForFinish=True))
current_i686_factory.addStep(ShellCommand(command=["sleep", "120"]))
current_i686_factory.addStep(trigger.Trigger(schedulerNames=['local_tests_i686'], waitForFinish=True))
current_i686_factory.addStep(trigger.Trigger(schedulerNames=['remote_tests_i686'], waitForFinish=True))

### current_am335x ###
current_am335x_factory = BuildFactory()
# check out the source
current_am335x_factory.addStep(Git(repourl=workspace_repourl, mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(360, 5)))
current_am335x_factory.addStep(ShellCommand(command=["ptxdist", "platform", "am335x"]))
current_am335x_factory.addStep(ShellCommand(command=["ptxdist", "select", "OrionLX-am335x-glibc"]))
current_am335x_factory.addStep(PTXDistBuild(command=["ptxdist", "go"]))
current_am335x_factory.addStep(ShellCommand(command=["ptxdist", "make", "ipkg-push"]))
current_am335x_factory.addStep(ShellCommand(command=["./scripts/ipkg-header"]))
current_am335x_factory.addStep(ShellCommand(command=["ptxdist", "collection", "am335x-base"]))
current_am335x_factory.addStep(ShellCommand(command=["ptxdist", "images"]))
current_am335x_factory.addStep(trigger.Trigger(schedulerNames=['upgrade_am335x'], waitForFinish=True))
current_am335x_factory.addStep(ShellCommand(command=["sleep", "120"]))
current_am335x_factory.addStep(trigger.Trigger(schedulerNames=['local_tests_am335x'], waitForFinish=True))
current_am335x_factory.addStep(trigger.Trigger(schedulerNames=['remote_tests_am335x'], waitForFinish=True))

### upgrade_i686 ###
upgrade_i686_factory = BuildFactory()
upgrade_i686_factory.addStep(ShellCommand(command=["upgrade", "list", "172.16.64.3/~georgem/ipkg-repository/OrionLX-i686-glibc/dists"]))
upgrade_i686_factory.addStep(ShellCommand(command=["opkg", "update"]))
upgrade_i686_factory.addStep(ShellCommand(command=["opkg", "upgrade"]))
upgrade_i686_factory.addStep(ShellCommand(command=["systemctl", "start", "delayed-reboot.timer"]))

### local_tests_i686 ###
local_tests_i686_factory = BuildFactory()
local_tests_i686_factory.addStep(ShellCommand(command=["uptime"]))
local_tests_i686_factory.addStep(ShellCommand(command=["uname", "-a"]))
local_tests_i686_factory.addStep(ShellCommand(command=["py.test"], workdir="/usr/local/OrionPythonTests"))

### remote_tests_i686 ###
remote_tests_i686_factory = BuildFactory()
remote_tests_i686_factory.addStep(Git(repourl=acceptance_test_repourl, alwaysUseLatest=True, mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(120, 5)))
remote_tests_i686_factory.addStep(ShellCommand(command=["py.test", "-s", "--orion=172.16.65.100", "--hub-address=172.16.64.25:4444", "--browser=chrome"], workdir='build/WebUI'))

### upgrade_am335x ###
upgrade_am335x_factory = BuildFactory()
upgrade_am335x_factory.addStep(ShellCommand(command=["upgrade", "list", "172.16.64.3/~georgem/ipkg-repository/OrionLX-am335x-glibc/dists"]))
upgrade_am335x_factory.addStep(ShellCommand(command=["opkg", "update"]))
upgrade_am335x_factory.addStep(ShellCommand(command=["opkg", "upgrade"]))
upgrade_am335x_factory.addStep(ShellCommand(command=["systemctl", "start", "delayed-reboot.timer"]))

### local_tests_am335x ###
local_tests_am335x_factory = BuildFactory()
local_tests_am335x_factory.addStep(ShellCommand(command=["uptime"]))
local_tests_am335x_factory.addStep(ShellCommand(command=["uname", "-a"]))
local_tests_am335x_factory.addStep(ShellCommand(command=["py.test"], workdir="/usr/local/OrionPythonTests"))

### remote_tests_am335x ###
remote_tests_am335x_factory = BuildFactory()
remote_tests_am335x_factory.addStep(Git(repourl=acceptance_test_repourl, alwaysUseLatest=True, mode="full", method="clobber", locks=[git_lock.access('exclusive')], retry=(120, 5)))
remote_tests_am335x_factory.addStep(ShellCommand(command=["py.test", "-s", "--orion=172.16.190.72", "--hub-address=172.16.64.25:4444", "--browser=chrome"], workdir='build/WebUI'))

from buildbot.config import BuilderConfig

c['builders'] = []
c['builders'].append(
    BuilderConfig(name="current_armeb_xscale",
      slavenames=["example-slave"],
      factory=current_armeb_xscale_factory))
c['builders'].append(
    BuilderConfig(name="local_tests_armeb_xscale",
      slavenames=["orion-armeb-xscale-slave"],
      factory=local_tests_armeb_xscale_factory))
c['builders'].append(
    BuilderConfig(name="remote_tests_armeb_xscale",
      slavenames=["example-slave"],
      factory=remote_tests_armeb_xscale_factory))
c['builders'].append(
    BuilderConfig(name="current_i686",
      slavenames=["example-slave"],
      factory=current_i686_factory))
c['builders'].append(
    BuilderConfig(name="current_am335x",
      slavenames=["example-slave"],
      factory=current_am335x_factory))
c['builders'].append(
    BuilderConfig(name="upgrade_i686",
      slavenames=["orion-i686-slave"],
      factory=upgrade_i686_factory))
c['builders'].append(
    BuilderConfig(name="local_tests_i686",
      slavenames=["orion-i686-slave"],
      factory=local_tests_i686_factory))
c['builders'].append(
    BuilderConfig(name="remote_tests_i686",
      slavenames=["example-slave"],
      factory=remote_tests_i686_factory))
c['builders'].append(
    BuilderConfig(name="upgrade_am335x",
      slavenames=["orion-am335x-slave"],
      factory=upgrade_am335x_factory))
c['builders'].append(
    BuilderConfig(name="local_tests_am335x",
      slavenames=["orion-am335x-slave"],
      factory=local_tests_am335x_factory))
c['builders'].append(
    BuilderConfig(name="remote_tests_am335x",
      slavenames=["example-slave"],
      factory=remote_tests_am335x_factory))
