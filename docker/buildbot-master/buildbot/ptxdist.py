import os
import string
from buildbot.plugins import *
from datetime import datetime
from buildbot.config import BuilderConfig

collections = {
    "armeb-xscale": "armeb-base",
    "i686": "i686-base",
    "am335x": "am335x-base",
}

# Workers
# The 'workers' list defines the set of recognized buildworkers. Each element is
# a Worker object, specifying a unique worker name and password.  The same
# worker name and password must be configured on the worker.
workers = [
    worker.Worker("worker-ptxdist", "pass", max_builds=1),
    worker.Worker("orion-i686-slave", "pass"),
    worker.Worker("orion-armeb-xscale-slave", "pass"),
    worker.Worker("orion-am335x-slave", "pass"),
]

worker_ptxdist_repourl = 'git@git.novatech-llc.com:andrew.cooper/workspace-ptxdist2.git'
worker_ptxdist_branch = 'docker-build'
acceptance_test_repourl = 'git@git.novatech-llc.com:NovaTech-Testing/AcceptanceTests.git'

# CHANGESOURCES
change_source = [
    changes.GitPoller(
        repourl=worker_ptxdist_repourl,
        branches=['master'],
        project='ptxdist',
        workdir='gitpoller-ptxdist')
]

# SCHEDULERS
schedulers = [
    # - Uncomment following to enabled automatic builds on workspace commit
    # SingleBranchScheduler(
    #                            name="current",
    #                            change_filter=filter.ChangeFilter(branch=None),
    #                            treeStableTimer=9*60,
    # builderNames=["current_armeb_xscale","current_i686", "current_am335x"]))

    # SingleBranchScheduler(
    #                            name="linux-3.2",
    #                            change_filter=filter.ChangeFilter(branch='branches/linux-3.2'),
    #                            treeStableTimer=9*60,
    #                            builderNames=["linux-3.2_armeb_xscale","linux-3.2_i686"]))
    # SingleBranchScheduler(
    #                            name="linux-3.8",
    #                            change_filter=filter.ChangeFilter(branch='branches/linux-3.8'),
    #                            treeStableTimer=9*60,
    #                            builderNames=["linux-3.8_am335x"]))
    schedulers.ForceScheduler(
        name="Force_PTXdist",
        builderNames=[
            "ptxdist_current",
            # "current_armeb_xscale",
            # "current_i686",
            # "current_am335x",
        ],
        properties=[
            util.ChoiceStringParameter(
                name="platform",
                label="ptxdist platform to build",
                choices=["armeb-xscale", "i686", "am335x"],
                strict=True
            ),
            util.StringParameter(
                name="version",
                label="distribution version",
                default='',
                required=True
            ),
            util.BooleanParameter(
                name='release',
                label="Make a release build",
                default=False
            ),
            util.StringParameter(
                name="packages",
                label="space-delimited list of packages to build",
                default='',
                required=False,
            ),
            util.BooleanParameter(
                name="clobber",
                label="Clobber build directory",
                default=False
            ),
        ],
    ),

    # schedulers.Nightly(
    #     name="ptxdist-nightly",
    #     branch=None,
    #     builderNames=[
    #         "current_armeb_xscale",
    #         "current_i686",
    #         "current_am335x",
    #     ],
    #     hour=22
    # ),

    schedulers.Triggerable(
        name="upgrade_i686",
        builderNames=["upgrade_i686"]),

    schedulers.Triggerable(
        name="local_tests_i686",
        builderNames=["local_tests_i686"]),

    schedulers.Triggerable(
        name="remote_tests_i686",
        builderNames=["remote_tests_i686"]),

    schedulers.Triggerable(
        name="local_tests_armeb_xscale",
        builderNames=["local_tests_armeb_xscale"]),

    schedulers.Triggerable(
        name="remote_tests_armeb_xscale",
        builderNames=["remote_tests_armeb_xscale"]),

    schedulers.Triggerable(
        name="upgrade_am335x",
        builderNames=["upgrade_am335x"]),

    schedulers.Triggerable(
        name="local_tests_am335x",
        builderNames=["local_tests_am335x"]),

    schedulers.Triggerable(
        name="remote_tests_am335x",
        builderNames=["remote_tests_am335x"]),
]

# BUILDERS

# The 'builders' list defines the Builders, which tell Buildbot how to perform a build:
# what steps, and which workers can execute them.  Note that any particular build will
# only take place on one worker.


class PTXDistBuildCounter(util.LogLineObserver):
    numTargets = 0
    numPackages = 0

    def outLineReceived(self, line):
        if line.startswith('finished target '):
            self.numTargets += 1
            self.step.setProgress('targets', self.numTargets)
            if line.strip().endswith('.targetinstall'):
                self.numPackages += 1
                self.step.setProgress('packages', self.numPackages)


class PTXDistBuild(steps.ShellCommand):

    def __init__(self, **kwargs):
        kwargs.setdefault('haltOnFailure', True)
        kwargs.setdefault('flunkOnFailure', True)

        steps.ShellCommand.__init__(self, **kwargs)   # always upcall!
        counter = PTXDistBuildCounter()
        self.addLogObserver('stdio', counter)
        self.progressMetrics += ('targets', 'packages')


git_lock = util.MasterLock("git")


@util.renderer
def CurrentTime(props):
    import string
    dt = datetime.now()
    dt.replace(microsecond=0)
    dts = string.replace(dt.isoformat(), ':', '.')
    return dts


# class PTXDistFactory(util.BuildFactory):

#     def __init__(self, repourl, branch, platform):
#         util.BuildFactory.__init__(self)
#         self.addStep(steps.SetProperty(
#             'platform',
#             platform))
#         self.addStep(steps.SetProperty(
#             'select',
#             util.Interpolate("OrionLX-%(prop:platform)s-glibc")))
#         self.addStep(steps.SetProperty(
#             'timestamp',
#             CurrentTime))
#         self.addStep(steps.SetProperty(
#             'dest',
#             util.Interpolate(
#                 "/cache/images/%(prop:buildername)s/%(prop:timestamp)s")))
#         self.addStep(steps.Git(
#             repourl=repourl,
#             branch=branch,
#             mode="full",
#             method="clobber",
#             locks=[git_lock.access('exclusive')],
#             retry=(360, 5)))
#         self.addStep(steps.ShellCommand(
#             command=["mkdir", "-p", util.Property('dest')]))
#         self.addStep(PTXDistBuild(
#             command=["ptxdist", "platform", util.Property("platform")]))
#         self.addStep(PTXDistBuild(
#             command=["ptxdist", "select", util.Property("select")]))
#         self.addStep(PTXDistBuild(
#             command=["python", "scripts/build.py", ]))
#         self.addStep(PTXDistBuild(
#             command=["ptxdist", "make", "ipkg-push"]))
#         self.addStep(PTXDistBuild(
#             command=["./scripts/ipkg-header"]))


def isReleaseBuild(step):
    if step.getProperty("release") is True:
        return True
    return False

# Create build factory for ptxdist
ptxdist_factory = util.BuildFactory()
ptxdist_factory.addSteps([

    # save current time
    steps.SetProperty('timestamp', CurrentTime),

    steps.SetProperty(
        'project',
        util.Interpolate(
            "OrionLX-%(prop:platform)s-glibc")
    ),
    
    # calculate and create output path
    steps.SetProperty(
        'dest',
        util.Interpolate("/cache/images/%(prop:platform)s/%(prop:timestamp)s")),
    steps.MakeDirectory(dir=util.Property('dest')),

    # calculate and create output path
    steps.SetProperty(
        'ipkg',
        util.Interpolate("/cache/ipkg-repository/%(prop:project)s")),
    steps.MakeDirectory(dir=util.Property('ipkg')),

    # check out the source
    steps.Git(
        repourl=worker_ptxdist_repourl,
        branch=worker_ptxdist_branch,
        mode="incremental",
        method="clobber",
        locks=[git_lock.access('exclusive')],
        retry=(360, 5)
        ),

    # set ptxdist build platform
    PTXDistBuild(
        command=[
            "ptxdist",
            "platform",
            util.Property("platform")
        ]),

    # set ptxdist target
    PTXDistBuild(
        command=[
            "ptxdist",
            "select",
            util.Property('project')
            ]),

    # run ptxdist build with build.py
    PTXDistBuild(
        command=[
            "python",
            "scripts/build.py",
            "--noclean",
            "--noconfirm",
            util.Property("version"),
            util.Interpolate("%(prop:release:#?|release|beta)s"),
            util.Transform(
                string.split,
                util.Property(
                    "packages",
                    default='')
                )
            ]),
    # PTXDistBuild(command=["ptxdist", "make", "ipkg-push"]),
    # PTXDistBuild(command=["./scripts/ipkg-header"]),

    # set ptxdist collection
    PTXDistBuild(
        command=[
            "ptxdist",
            "collection",
            util.Transform(collections.get, util.Property("platform"))
            ]),

    # If building a release, create and copy images
    PTXDistBuild(
        command=["ptxdist", "images"],
        doStepIf=isReleaseBuild
        ),
    steps.CopyDirectory(
        src=util.Interpolate("platform-%(prop:platform)s/images"),
        dest=util.Property('dest'),
        doStepIf=isReleaseBuild
        ),
])
# ptxdist_factory.addStep(steps.ShellCommand(command=["./scripts/build-upgrade-test.sh"]))
# ptxdist_factory.addStep(steps.ShellCommand(command=["curl", "--progress-bar", "-o", "/dev/null", "http://george:1234@172.16.190.70/outlet?1=CCL"]))
# ptxdist_factory.addStep(steps.ShellCommand(command=[
# 	"./scripts/upgradetest.py",
# 	"load_7_upgrade_to_8",
# 	"/srv/tftp/root.jffs2_64",
# 	"/home/georgem/testrack0",
# 	"172.16.64.150",
# 	"--install-path", "172.16.64.3/~georgem/ipkg-repository/OrionLX-armeb-xscale-glibc/dists",
# 	"--packages",
# 	"buildbot-slave",
# 	"orionpythontests",
# 	"orionprotocoltests",
# 	"--orion-config", "./local-pkg/buildslave_config_armeb-xscale.tar.gz"]))
# ptxdist_factory.addStep(trigger.Trigger(schedulerNames=['local_tests_armeb_xscale']))
# ptxdist_factory.addStep(trigger.Trigger(schedulerNames=['remote_tests_armeb_xscale']))

# local_tests_armeb_xscale #
local_tests_armeb_xscale_factory = util.BuildFactory()
local_tests_armeb_xscale_factory.addStep(
    steps.ShellCommand(command=["uptime"]))
local_tests_armeb_xscale_factory.addStep(
    steps.ShellCommand(command=["uname", "-a"]))
local_tests_armeb_xscale_factory.addStep(steps.ShellCommand(
    command=["py.test"], workdir="/usr/local/OrionPythonTests"))

# remote_tests_armeb_xscale #
remote_tests_armeb_xscale_factory = util.BuildFactory()
# check out the source
remote_tests_armeb_xscale_factory.addStep(steps.Git(repourl=acceptance_test_repourl, alwaysUseLatest=True,
                                                    mode="incremental", method="clobber", locks=[git_lock.access('exclusive')], retry=(120, 5)))
remote_tests_armeb_xscale_factory.addStep(steps.ShellCommand(
    command=["py.test", "-s", "--orion=172.16.64.150", "--hub-address=172.16.64.25:4444", "--browser=chrome"], workdir='build/WebUI'))

# current_i686 #
# current_i686_factory = PTXDistFactory(
#     worker_ptxdist_repourl, worker_ptxdist_branch, 'i686')
# # check out the source
# current_i686_factory.addStep(PTXDistBuild(
#     command=["ptxdist", "collection", "i686-base"]))
# current_i686_factory.addStep(PTXDistBuild(command=["ptxdist", "images"]))
# current_i686_factory.addStep(steps.ShellCommand(
#     command=["gzip", "-f", "platform-i686/images/hd.img"]))
# current_i686_factory.addStep(steps.ShellCommand(
#     command=["cp", "platform-i686/images/hd.img.gz", util.Property('dest')]))
# current_i686_factory.addStep(trigger.Trigger(schedulerNames=['upgrade_i686']))
# current_i686_factory.addStep(steps.ShellCommand(command=["sleep", "120"]))
# current_i686_factory.addStep(trigger.Trigger(schedulerNames=['local_tests_i686']))
# current_i686_factory.addStep(trigger.Trigger(schedulerNames=['remote_tests_i686']))

# current_am335x #
# current_am335x_factory = PTXDistFactory(
#     worker_ptxdist_repourl, worker_ptxdist_branch, 'am335x')
# # check out the source
# current_am335x_factory.addStep(PTXDistBuild(
#     command=["ptxdist", "collection", "am335x-base"]))
# current_am335x_factory.addStep(PTXDistBuild(command=["ptxdist", "images"]))
# current_am335x_factory.addStep(trigger.Trigger(schedulerNames=['upgrade_am335x']))
# current_am335x_factory.addStep(steps.ShellCommand(command=["sleep", "120"]))
# current_am335x_factory.addStep(trigger.Trigger(schedulerNames=['local_tests_am335x']))
# current_am335x_factory.addStep(trigger.Trigger(schedulerNames=['remote_tests_am335x']))

# upgrade_i686 #
upgrade_i686_factory = util.BuildFactory()
upgrade_i686_factory.addStep(steps.ShellCommand(command=[
                             "upgrade", "list", "172.16.64.3/~georgem/ipkg-repository/OrionLX-i686-glibc/dists"]))
upgrade_i686_factory.addStep(steps.ShellCommand(command=["opkg", "update"]))
upgrade_i686_factory.addStep(steps.ShellCommand(command=["opkg", "upgrade"]))
upgrade_i686_factory.addStep(steps.ShellCommand(
    command=["systemctl", "start", "delayed-reboot.timer"]))

# local_tests_i686 #
local_tests_i686_factory = util.BuildFactory()
local_tests_i686_factory.addStep(steps.ShellCommand(command=["uptime"]))
local_tests_i686_factory.addStep(steps.ShellCommand(command=["uname", "-a"]))
local_tests_i686_factory.addStep(steps.ShellCommand(
    command=["py.test"], workdir="/usr/local/OrionPythonTests"))

# remote_tests_i686 #
remote_tests_i686_factory = util.BuildFactory()
remote_tests_i686_factory.addStep(steps.Git(repourl=acceptance_test_repourl, alwaysUseLatest=True,
                                            mode="incremental", method="clobber", locks=[git_lock.access('exclusive')], retry=(120, 5)))
remote_tests_i686_factory.addStep(steps.ShellCommand(command=[
                                  "py.test", "-s", "--orion=172.16.65.100", "--hub-address=172.16.64.25:4444", "--browser=chrome"], workdir='build/WebUI'))

# upgrade_am335x #
upgrade_am335x_factory = util.BuildFactory()
upgrade_am335x_factory.addStep(steps.ShellCommand(command=[
                               "upgrade", "list", "172.16.64.3/~georgem/ipkg-repository/OrionLX-am335x-glibc/dists"]))
upgrade_am335x_factory.addStep(steps.ShellCommand(command=["opkg", "update"]))
upgrade_am335x_factory.addStep(steps.ShellCommand(command=["opkg", "upgrade"]))
upgrade_am335x_factory.addStep(steps.ShellCommand(
    command=["systemctl", "start", "delayed-reboot.timer"]))

# local_tests_am335x #
local_tests_am335x_factory = util.BuildFactory()
local_tests_am335x_factory.addStep(steps.ShellCommand(command=["uptime"]))
local_tests_am335x_factory.addStep(steps.ShellCommand(command=["uname", "-a"]))
local_tests_am335x_factory.addStep(steps.ShellCommand(
    command=["py.test"], workdir="/usr/local/OrionPythonTests"))

# remote_tests_am335x #
remote_tests_am335x_factory = util.BuildFactory()
remote_tests_am335x_factory.addStep(steps.Git(repourl=acceptance_test_repourl, alwaysUseLatest=True,
                                              mode="incremental", method="clobber", locks=[git_lock.access('exclusive')], retry=(120, 5)))
remote_tests_am335x_factory.addStep(steps.ShellCommand(command=[
                                    "py.test", "-s", "--orion=172.16.190.72", "--hub-address=172.16.64.25:4444", "--browser=chrome"], workdir='build/WebUI'))

builders = []
builders.append(
    BuilderConfig(
        name="ptxdist_current",
        workernames=["worker-ptxdist"],
        factory=ptxdist_factory
    )
)
# builders.append(
#     BuilderConfig(name="current_armeb_xscale",
#                   workernames=["worker-ptxdist"],
#                   factory=current_armeb_xscale_factory))
builders.append(
    BuilderConfig(name="local_tests_armeb_xscale",
                  workernames=["orion-armeb-xscale-slave"],
                  factory=local_tests_armeb_xscale_factory))
builders.append(
    BuilderConfig(name="remote_tests_armeb_xscale",
                  workernames=["worker-ptxdist"],
                  factory=remote_tests_armeb_xscale_factory))
# builders.append(
#     BuilderConfig(name="current_i686",
#                   workernames=["worker-ptxdist"],
#                   factory=current_i686_factory))
# builders.append(
#     BuilderConfig(name="current_am335x",
#                   workernames=["worker-ptxdist"],
#                   factory=current_am335x_factory))
builders.append(
    BuilderConfig(name="upgrade_i686",
                  workernames=["orion-i686-slave"],
                  factory=upgrade_i686_factory))
builders.append(
    BuilderConfig(name="local_tests_i686",
                  workernames=["orion-i686-slave"],
                  factory=local_tests_i686_factory))
builders.append(
    BuilderConfig(name="remote_tests_i686",
                  workernames=["worker-ptxdist"],
                  factory=remote_tests_i686_factory))
builders.append(
    BuilderConfig(name="upgrade_am335x",
                  workernames=["orion-am335x-slave"],
                  factory=upgrade_am335x_factory))
builders.append(
    BuilderConfig(name="local_tests_am335x",
                  workernames=["orion-am335x-slave"],
                  factory=local_tests_am335x_factory))
builders.append(
    BuilderConfig(name="remote_tests_am335x",
                  workernames=["worker-ptxdist"],
                  factory=remote_tests_am335x_factory))
