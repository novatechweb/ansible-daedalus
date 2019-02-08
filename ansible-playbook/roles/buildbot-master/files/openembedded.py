"""
    Buildbot configuration for NovaTech Open-Embedded builds
"""

import os
from buildbot.plugins import *

c = WorkerConfig = {}


DEFAULT_BBFLAGS = '-k'
DEFAULT_REPO = 'git@git.novatech-llc.com:ntel/setup-scripts.git'

BETA_URI = os.getenv("NTEL_BETA_URI", default="http://127.0.0.1")
RELEASE_URI = os.getenv("NTEL_RELEASE_URI", default="http://127.0.0.1")
SSTATE_URI = os.getenv("NTEL_SSTATE_URI", default="http://127.0.0.1")

# Workers
# The 'workers' list defines the set of recognized buildworkers. Each element is
# a Worker object, specifying a unique worker name and password.  The same
# worker name and password must be configured on the worker.
c['workers'] = [
    worker.Worker("worker-ntel", "pass", max_builds=3),
]

# CHANGESOURCES
c['change_source'] = [
    changes.GitPoller(
        repourl=DEFAULT_REPO,
        branches=['master', 'morty'],
        project='ntel',
        workdir='gitpoller-ntel')
]

# SCHEDULERS
c['schedulers'] = [
    schedulers.ForceScheduler(
        name="Force",
        label="Force NTEL OpenEmbedded Build",
        builderNames=[
            "ntel-orionlxm",
            "ntel-orionlx-cpx",
            "ntel-orionlx-plus",
            "ntel-orion-io",
            "ntel-qemux86-64",
            "ntel-all"
        ],
        codebases=[
            util.CodebaseParameter(
                "",
                label="Main repository",
                # will generate a combo box
                branch=util.StringParameter(
                    name="branch",
                    default="morty"),
                repository=util.StringParameter(
                    name="repository",
                    default=DEFAULT_REPO),

                # will generate nothing in the form, but revision, repository,
                # and project are needed by buildbot scheduling system so we
                # need to pass a value ("")
                revision=util.FixedParameter(name="revision", default=""),
                project=util.FixedParameter(
                    name="project", default="ntel-oe"),
            )
        ],
        properties=[
            util.BooleanParameter(
                name="clobber",
                label="Clobber build directory",
                default=False),
            util.BooleanParameter(
                name='cache',
                label="Use cached state",
                default=True),
            util.StringParameter(
                name="release_pin",
                label="PIN for release signing",
                default='',
                required=False),
            util.StringParameter(
                name='bbflags',
                label="BitBake Options",
                default=DEFAULT_BBFLAGS),
            util.StringParameter(
                name="release_pin",
                label="PIN for release signing",
                default='',
                required=False,
            ),
            util.StringParameter(
                name='bbflags',
                label="BitBake Options",
                default=DEFAULT_BBFLAGS
            ),
        ],
    ),

    schedulers.Nightly(
        name="ntel-nightly",
        branch=None,
        builderNames=[
            "ntel-orionlxm",
            "ntel-orionlx-cpx",
            "ntel-orionlx-plus",
            "ntel-orion-io",
            "ntel-qemux86-64",
            "ntel-all"
        ],
        codebases={
            '': {
                'repository': DEFAULT_REPO,
                'branch': 'morty',
                'revision': '',
            }
        },
        properties={
            'clobber': True,
            'cache': True,
            'bbflags': DEFAULT_BBFLAGS
        },
        hour=22
    ),

]

# BUILDERS
# The 'builders' list defines the Builders, which tell Buildbot how to perform
# a build: what steps, and which workers can execute them.  Note that any
# particular build will only take place on one worker.
c['builders'] = []

git_lock = util.MasterLock("git")


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

    newprops['artifacts'] = {}
    machines = [props.getProperty('machine')]

    mc = props.getProperty('multiconfig')
    if mc:
        machines.extend(mc.split(' '))

    for m in machines:
        a = {}

        a['dest'] = "/cache/images/%s" % (
            props.getProperty('buildername')
        )

        a['prefix'] = "%s-%s" % (
            m,
            version,
        )

        a['artifact'] = "%s.tar.gz" % (
            a['prefix'],
        )

        if props.getProperty('release_pin'):
            uri = RELEASE_URI
        else:
            uri = BETA_URI

        a['url'] = os.path.join(
            uri,
            version,
            a['artifact'],
        )

        newprops['artifacts'][m] = a

    bbflags = props.getProperty('bbflags', DEFAULT_BBFLAGS)
    cache = props.getProperty('cache', True)
    if not cache:
        newprops['bbflags'] = '%s --no-setscene' % (bbflags)

    return newprops


auto_conf = [
    '# MACHINE selection',
    'MACHINE                = "%(prop:machine)s"',
    '%(prop:multiconfig:+'
    'BBMULTICONFIG          = "%(prop:multiconfig)s")s',
    '',
    '# Directories for cached downloads and state',
    'DL_DIR                 = "/cache/downloads"',
    'SSTATE_DIR             = "/cache/sstate"',
    'PREMIRRORS_prepend     = "ftp://.*/.* file:///cache/premirrors/ \\n"',
    'PREMIRRORS_prepend     = "https?$://.*/.* file:///cache/premirrors/ \\n"',
    'MIRRORS_prepend        = "ftp://.*/.* file:///cache/mirrors/ \\n"',
    'MIRRORS_prepend        = "https?$://.*/.* file:///cache/mirrors/ \\n"',
    'SSTATE_MIRRORS_prepend = "file://.* file:///cache/sstate/PATH \\n"',
    'unset PRSERV_HOST',
    '',
    '# Release signing configuration',
    '%(prop:release_pin:+'
    'PKCS11_PIN             = "%(prop:release_pin)s")s',
    'include %(prop:release_pin:#?|release.conf|test.conf)s',
    '',
]


class BitBakeConf(steps.StringDownload):

    def __init__(self, args, **kw):
        lines = list(args)
        configstring = '\n'.join(lines)
        conf_file = kw.setdefault('conf_file', 'auto.conf')
        sdkw = {
            'name': 'generate %s' % (conf_file),
            'workerdest': 'conf/%s' % (conf_file),
        }
        steps.StringDownload.__init__(
            self, util.Interpolate(configstring, **kw), **sdkw)


class BitBake(steps.Compile):

    def __init__(self, package, **kwargs):

        kw = {
            'command': [
                'bash',
                '-c',
                util.Interpolate(
                    'bitbake %(prop:bbflags)s %(kw:package)s',
                    package=package
                )
            ],
            'description': 'building',
            'descriptionDone': 'build',
            'env': {
                'ENV': 'environment-ntel',
                'BASH_ENV': 'environment-ntel',
            },
            'flunkOnFailure': True,
            'haltOnFailure': True,
            'name': 'bitbake',
            'timeout': int(os.getenv('LONG_RUN_TIMEOUT', 600)),
            'warningPattern': "^WARNING: ",
        }
        kw.update(kwargs)
        steps.Compile.__init__(self, **kw)


class BitBakeArchive(steps.ShellSequence):

    def __init__(self, **kwargs):
        kw = {
            'description': 'archiving',
            'descriptionDone': 'archive',
            'env': {
                'ENV': 'environment-ntel',
                'BASH_ENV': 'environment-ntel',
            },
            'flunkOnFailure': True,
            'haltOnFailure': True,
            'name': 'archive',
            'timeout': int(os.getenv('LONG_RUN_TIMEOUT', 600)),
        }
        kw.update(kwargs)
        kw = self.setupShellMixin(kw)
        steps.ShellSequence.__init__(self, **kw)

    def run(self):
        commands = []

        artifacts = self.getProperty('artifacts')
        for m, art in artifacts.iteritems():
            commands.append(util.ShellArg(
                command="echo 'MACHINE=\"%s\"' >> conf/auto.conf" % (m),
            ))

            artfile = os.path.join(art['dest'], art['artifact'])
            commands.append(util.ShellArg(
                command=[
                    'ci-archive.sh',
                    art['prefix'],
                    artfile
                ],
                haltOnFailure=True,
                logfile="Create %s archive" % (m),
            ))

            arturl = art['url']
            commands.append(util.ShellArg(
                logfile="Upload %s archive" % (m),
                haltOnFailure=True,
                command=[
                    'curl', '--fail', '--netrc', '--verbose',
                    '--upload-file', artfile,
                    '--url', arturl
                ],
            ))
        return steps.ShellSequence.runShellSequence(self, commands)


class BitBakeFactory(util.BuildFactory):

    def __init__(self, *build_steps):
        util.BuildFactory.__init__(self)
        self.addStep(steps.SetProperties(ComputeBuildProperties))
        self.addStep(steps.GitLab(
            repourl=util.Property('repository', default=DEFAULT_REPO),
            branch=util.Property('branch', default=DEFAULT_BRANCH),
            mode=util.Interpolate("%(prop:clobber:#?|full|incremental)s"),
            method="clobber",
            locks=[git_lock.access('exclusive')],
            retry=(360, 5)))
        self.addStep(steps.ShellCommand(
            name="configure",
            description="configuring",
            descriptionDone="configured",
            command=["./oebb.sh", "config", util.Property('machine')]))
        self.addStep(BitBakeConf(auto_conf, conf_file='auto.conf'))

        if build_steps:
            self.addSteps(build_steps)
        self.addStep(BitBakeArchive())


c['builders'].append(
    util.BuilderConfig(
        description="OrionLXm",
        name="ntel-orionlxm",
        workernames=["worker-ntel"],
        factory=BitBakeFactory(
            BitBake("orionlxm-swu-image", name="swu image"),
            BitBake("orionlxm-disk-swu-image", name="disk swu image"),
            BitBake("orion-headless-image -c populate_sdk", name="SDK"),
        ),
        properties={
            'machine': 'orionlxm',
            'repository': DEFAULT_REPO,
        }
    ))

c['builders'].append(
    util.BuilderConfig(
        description="Orion I/O",
        name="ntel-orion-io",
        workernames=["worker-ntel"],
        factory=BitBakeFactory(
            BitBake("-c cleanall u-boot-orion-io", name="cleanup"),
            BitBake("orion-io-swu-image", name="swu image"),
            BitBake("orion-headless-image -c populate_sdk", name="SDK"),
        ),
        properties={
            'machine': 'orion-io',
            'repository': DEFAULT_REPO,
        }
    ))

c['builders'].append(
    util.BuilderConfig(
        description="OrionLX (CPX)",
        name="ntel-orionlx-cpx",
        workernames=["worker-ntel"],
        factory=BitBakeFactory(
            BitBake("-c cleanall gdk-pixbuf-native librsvg-native gtk-icon-utils-native", name="cleanup"),
            BitBake("orionlx-cpx-swu-image", name="swu image"),
            BitBake("orionlx-cpx-disk-swu-image", name="disk swu image"),
            BitBake("orion-graphical-image -c populate_sdk", name="SDK"),
        ),
        properties={
            'machine': 'orionlx-cpx',
            'repository': DEFAULT_REPO,
        }
    ))

c['builders'].append(
    util.BuilderConfig(
        description="OrionLX (Plus)",
        name="ntel-orionlx-plus",
        workernames=["worker-ntel"],
        factory=BitBakeFactory(
            BitBake("-c cleanall gdk-pixbuf-native librsvg-native gtk-icon-utils-native", name="cleanup"),
            BitBake("orionlx-plus-swu-image", name="swu image"),
            BitBake("orion-graphical-image -c populate_sdk", name="SDK"),
        ),
        properties={
            'machine': 'orionlx-plus',
            'repository': DEFAULT_REPO,
        }
    ))

c['builders'].append(
    util.BuilderConfig(
        description="Orion (qemu)",
        name="ntel-qemux86-64",
        workernames=["worker-ntel"],
        factory=BitBakeFactory(
            BitBake("gdk-pixbuf-native:do_cleanall", name="cleanup"),
            BitBake("orion-graphical-image", name="image"),
            BitBake("orion-graphical-image -c populate_sdk", name="SDK"),
        ),
        properties={
            'machine': 'qemux86-64',
            'repository': DEFAULT_REPO,
        }
    ))

multiconfig = ['orionlx-cpx', 'orionlx-plus', 'orionlxm', 'orion-io']
c['builders'].append(
    util.BuilderConfig(
        description="Orion (all)",
        name="ntel-all",
        workernames=["worker-ntel"],
        factory=BitBakeFactory(
            BitBake(" gdk-pixbuf-native:do_cleanall"
                    " multiconfig:orionlx-cpx:gdk-pixbuf-native:do_cleanall"
                    " multiconfig:orionlx-plus:gdk-pixbuf-native:do_cleanall",
                    name="cleanup"),
            BitBake(" orion-graphical-image"
                    " multiconfig:orionlx-cpx:orionlx-cpx-swu-image"
                    " multiconfig:orionlx-cpx:orionlx-cpx-disk-swu-image"
                    " multiconfig:orionlx-plus:orionlx-plus-swu-image"
                    " multiconfig:orionlxm:orionlxm-swu-image"
                    " multiconfig:orion-io:orion-io-swu-image",
                    name="images"),
        ),
        properties={
            'machine': 'qemux86-64',
            'repository': DEFAULT_REPO,
            'multiconfig': ' '.join(multiconfig),
        }
    ))
