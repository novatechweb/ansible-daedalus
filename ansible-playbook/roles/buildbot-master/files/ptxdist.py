import os
import string
from buildbot.plugins import *
from datetime import datetime
from buildbot.config import BuilderConfig

c = WorkerConfig = {}

DEFAULT_BRANCH = 'master'
DEFAULT_REPO = 'git@git.novatech-llc.com:Orion-ptxdist/workspace-ptxdist2'

BETA_URI = os.getenv("PTXDIST_BETA_URI", default="http://127.0.0.1")
RELEASE_URI = os.getenv("PTXDIST_RELEASE_URI", default="http://127.0.0.1")

collections = {
    "armeb-xscale": "armeb-base",
    "i686": "i686-base",
    "am335x": "am335x-base",
}

# Workers
# The 'workers' list defines the set of recognized buildworkers. Each element is
# a Worker object, specifying a unique worker name and password.  The same
# worker name and password must be configured on the worker.
c['workers'] = [
    worker.Worker("worker-ptxdist", "pass", max_builds=3),
    worker.Worker("orion-i686-slave", "pass", max_builds=1),
    worker.Worker("orion-armeb-xscale-slave", "pass", max_builds=1),
    worker.Worker("orion-am335x-slave", "pass", max_builds=1),
]

acceptance_test_repourl = 'git@git.novatech-llc.com:NovaTech-Testing/AcceptanceTests.git'

# CHANGESOURCES
c['change_source'] = [
    changes.GitPoller(
        repourl=DEFAULT_REPO,
        branches=[DEFAULT_BRANCH],
        project='ptxdist',
        workdir='gitpoller-ptxdist')
]

# SCHEDULERS
c['schedulers'] = [
    # - Uncomment following to enabled automatic builds on workspace commit
    # SingleBranchScheduler(
    #                            name="current",
    #                            change_filter=filter.ChangeFilter(branch=None),
    #                            treeStableTimer=9*60,
    # builderNames=["current_armeb_xscale","current_i686", "current_am335x"]))

    schedulers.ForceScheduler(
        name="ptxdist-force",
        label="Force PTXdist Build",
        builderNames=[
            "force-armeb-xscale",
            "force-i686",
            "force-am335x",
        ],
        codebases=[
            util.CodebaseParameter(
                codebase="orion-ptxdist-workspace",
                label="Build Source",
                # will generate a combo box
                repository=util.StringParameter(
                    name="repository",
                    default=DEFAULT_REPO),
                branch=util.StringParameter(
                    name="branch",
                    default=DEFAULT_BRANCH),
                revision=util.StringParameter(
                    name="revision",
                    default="")
            )
        ],
        properties=[
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
c['builders'] = []

git_lock = util.MasterLock("git")


class PTXDistBuild(steps.ShellSequence):
    def __init__(self, **kwargs):
        kwargs.setdefault('haltOnFailure', True)
        kwargs.setdefault('flunkOnFailure', True)
        kwargs.setdefault('timeout', int(os.getenv('LONG_RUN_TIMEOUT', 1200)))

        steps.ShellSequence.__init__(self, **kwargs)

        self.name = "PTXDist Build"
        self.description = "building"
        self.descriptionDone = "built"
        self.commands = [
            # set ptxdist build platform
            util.ShellArg(
                haltOnFailure=True,
                command=[
                    "ptxdist",
                    "platform",
                    util.Property("platform")
                ]),

            # set ptxdist target
            util.ShellArg(
                haltOnFailure=True,
                command=[
                    "ptxdist",
                    "select",
                    util.Property('project')
                ]),

            # run ptxdist build with build.py
            util.ShellArg(
                logfile="ptxdist build",
                haltOnFailure=True,
                command=util.FlattenList([
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
                ])),

            util.ShellArg(
                logfile="archive",
                haltOnFailure=True,
                command=[
                    "tar", "-v", "-c", "-z",
                    "-C", util.Property("ipkg_root"),
                    "-f", util.Interpolate("%(prop:artifact_dest)s/%(prop:ipkg_artifact)s"),
                    util.Property("project")
                ]),

            util.ShellArg(
                logfile="upload",
                haltOnFailure=True,
                command=[
                    'curl', '--netrc', '--verbose',
                    '--upload-file', util.Interpolate("%(prop:artifact_dest)s/%(prop:image_artifact)s"),
                    '--url', util.Property('ipkg_url')
                ]),
        ]


class PTXDistImages(steps.ShellSequence):

    def __init__(self, **kwargs):
        kwargs.setdefault('haltOnFailure', True)
        kwargs.setdefault('flunkOnFailure', True)

        steps.ShellSequence.__init__(self, **kwargs)

        self.name = "PTXDist Images"
        self.description = "making images"
        self.descriptionDone = "images"
        self.commands = [
            util.ShellArg(
                haltOnFailure=True,
                command=[
                    "ptxdist",
                    "collection",
                    util.Property("collection")
                ]),

            util.ShellArg(
                logfile="ptxdist images",
                haltOnFailure=True,
                command=[
                    "ptxdist",
                    "images"
                ]),

            util.ShellArg(
                logfile="archive",
                haltOnFailure=True,
                command=[
                    "tar", "-v", "-c", "-z",
                    "-C", util.Property("image_root"),
                    "-f", util.Interpolate("%(prop:artifact_dest)s/%(prop:image_artifact)s"),
                    "."
                ]),

            util.ShellArg(
                logfile="upload",
                haltOnFailure=False,
                flunkOnFailure=True,
                command=[
                    'curl', '--netrc', '--verbose',
                    '--upload-file', util.Interpolate("%(prop:artifact_dest)s/%(prop:image_artifact)s"),
                    '--url', util.Property('image_url')
                ]),
        ]


def CurrentTime():
    from datetime import datetime
    import string
    dt = datetime.now()
    dt.replace(microsecond=0)
    dts = string.replace(dt.isoformat(), ':', '.')
    return dts


@util.renderer
def ComputeBuildProperties(props):
    newprops = {}

    newprops['timestamp'] = CurrentTime()

    version = props.getProperty('version')
    if not version:
        version = newprops['timestamp']

    newprops['project'] = "OrionLX-%s-glibc" % (
        props.getProperty("platform")
    )

    newprops['artifact_dest'] = "/cache/artifacts/%s" % (
        version,
    )

    newprops['image_root'] = "%s/build/platform-%s/images" % (
        props.getProperty("builddir"),
        props.getProperty("platform"),
    )

    newprops['image_artifact'] = "%s-%s.images.tar.gz" % (
        newprops['project'],
        version,
    )

    newprops['ipkg_root'] = "/cache/ipkg-repository"

    newprops['ipkg_repo'] = "%s/%s" % (
        newprops['ipkg_root'],
        newprops['project'],
    )

    newprops['ipkg_artifact'] = "%s-%s.ipkg.tar.gz" % (
        newprops['project'],
        version,
    )

    newprops['collection'] = collections.get(
        props.getProperty('platform')
    )

    if props.getProperty('release'):
        uri = RELEASE_URI
    else:
        uri = BETA_URI

    newprops['ipkg_url'] = os.path.join(
        uri,
        version,
        newprops['ipkg_artifact'],
    )

    newprops['image_url'] = os.path.join(
        uri,
        version,
        newprops['image_artifact'],
    )

    return newprops


def isReleaseBuild(step):
    if step.getProperty("release") is True:
        return True
    return False

# Create build factory for ptxdist
ptxdist_factory = util.BuildFactory([
    steps.SetProperties(ComputeBuildProperties),

    steps.MakeDirectory(dir=util.Property('artifact_dest')),

    steps.MakeDirectory(dir=util.Property('ipkg_repo')),

    # check out the source
    steps.Git(
        codebase=util.Property('codebase'),
        repourl=util.Property('repository'),
        branch=util.Property('branch'),
        mode=util.Interpolate("%(prop:clobber:#?|full|incremental)s"),
        method="clobber",
    ),

    PTXDistBuild(),

    PTXDistImages(
        doStepIf=isReleaseBuild,
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
                                                    mode="incremental", method="clobber", retry=(120, 5)))
remote_tests_armeb_xscale_factory.addStep(steps.ShellCommand(
    command=["py.test", "-s", "--orion=172.16.64.150", "--hub-address=172.16.64.25:4444", "--browser=chrome"], workdir='build/WebUI'))

# current_i686 #
# current_i686_factory.addStep(steps.ShellCommand(
#     command=["gzip", "-f", "platform-i686/images/hd.img"]))
# current_i686_factory.addStep(steps.ShellCommand(
#     command=["cp", "platform-i686/images/hd.img.gz", util.Property('dest')]))
# current_i686_factory.addStep(trigger.Trigger(schedulerNames=['upgrade_i686']))
# current_i686_factory.addStep(steps.ShellCommand(command=["sleep", "120"]))
# current_i686_factory.addStep(trigger.Trigger(schedulerNames=['local_tests_i686']))
# current_i686_factory.addStep(trigger.Trigger(schedulerNames=['remote_tests_i686']))

# current_am335x #
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
                                            mode="incremental", method="clobber", retry=(120, 5)))
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
                                              mode="incremental", method="clobber", retry=(120, 5)))
remote_tests_am335x_factory.addStep(steps.ShellCommand(command=[
                                    "py.test", "-s", "--orion=172.16.190.72", "--hub-address=172.16.64.25:4444", "--browser=chrome"], workdir='build/WebUI'))

c['builders'] = []
c['builders'].append(
    BuilderConfig(name="force-armeb-xscale",
                  workernames=["worker-ptxdist"],
                  factory=ptxdist_factory,
                  properties={
                      'platform': 'armeb-xscale',
                  }))
c['builders'].append(
    BuilderConfig(name="force-i686",
                  workernames=["worker-ptxdist"],
                  factory=ptxdist_factory,
                  properties={
                      'platform': 'i686',
                  }))
c['builders'].append(
    BuilderConfig(name="force-am335x",
                  workernames=["worker-ptxdist"],
                  factory=ptxdist_factory,
                  properties={
                      'platform': 'am335x',
                  }))

c['builders'].append(
    BuilderConfig(name="local_tests_armeb_xscale",
                  workernames=["orion-armeb-xscale-slave"],
                  factory=local_tests_armeb_xscale_factory))
c['builders'].append(
    BuilderConfig(name="local_tests_i686",
                  workernames=["orion-i686-slave"],
                  factory=local_tests_i686_factory))
c['builders'].append(
    BuilderConfig(name="local_tests_am335x",
                  workernames=["orion-am335x-slave"],
                  factory=local_tests_am335x_factory))

c['builders'].append(
    BuilderConfig(name="remote_tests_armeb_xscale",
                  workernames=["worker-ptxdist"],
                  factory=remote_tests_armeb_xscale_factory))
c['builders'].append(
    BuilderConfig(name="remote_tests_i686",
                  workernames=["worker-ptxdist"],
                  factory=remote_tests_i686_factory))
c['builders'].append(
    BuilderConfig(name="remote_tests_am335x",
                  workernames=["worker-ptxdist"],
                  factory=remote_tests_am335x_factory))

c['builders'].append(
    BuilderConfig(name="upgrade_i686",
                  workernames=["orion-i686-slave"],
                  factory=upgrade_i686_factory))
c['builders'].append(
    BuilderConfig(name="upgrade_am335x",
                  workernames=["orion-am335x-slave"],
                  factory=upgrade_am335x_factory))
