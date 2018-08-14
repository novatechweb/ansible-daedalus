"""
    Buildbot configuration for NovaTech Open-Embedded builds
"""

import os
from buildbot.plugins import *

c = WorkerConfig = {}


DEFAULT_BBFLAGS = '-k'
DEFAULT_CODEBASE = "ntel/setup-scripts"

# Workers
# The 'workers' list defines the set of recognized buildworkers. Each element is
# a Worker object, specifying a unique worker name and password.  The same
# worker name and password must be configured on the worker.
c['workers'] = [
    worker.Worker("worker-ntel", "pass", max_builds=1),
]

DEFAULT_REPO = 'git@git.novatech-llc.com:ntel/setup-scripts.git'

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
    schedulers.SingleBranchScheduler(
        name="ntel-push",
        builderNames=[
            "ntel-orionlxm",
            "ntel-orionlx-cpx",
            "ntel-orionlx-plus",
            "ntel-orion-io",
            "ntel-qemux86-64",
            "ntel-all",
        ],
        change_filter=util.ChangeFilter(
            codebase=DEFAULT_CODEBASE,
            category='push',
        ),
        codebases=[
            DEFAULT_CODEBASE
        ],
        properties={
            'clobber': False,
            'cache': True,
            'release_pin': None,
            'bbflags': DEFAULT_BBFLAGS,
        },
        treeStableTimer=5,
    ),

    schedulers.SingleBranchScheduler(
        name="ntel-merge-request",
        builderNames=[
            "ntel-orionlxm",
            "ntel-orionlx-cpx",
            "ntel-orionlx-plus",
            "ntel-orion-io",
            "ntel-qemux86-64",
            "ntel-all",
        ],
        change_filter=util.ChangeFilter(
            codebase=DEFAULT_CODEBASE,
            category='merge_request',
        ),
        codebases=[
            DEFAULT_CODEBASE
        ],
        properties={
            'clobber': False,
            'cache': True,
            'release_pin': None,
            'bbflags': DEFAULT_BBFLAGS,
        },
        treeStableTimer=5,
    ),

    schedulers.ForceScheduler(
        name="ntel-force",
        label="Force NTEL OpenEmbedded Build",
        builderNames=[
            "ntel-orionlxm",
            "ntel-orionlx-cpx",
            "ntel-orionlx-plus",
            "ntel-orion-io",
            "ntel-qemux86-64",
            "ntel-all",
        ],
        codebases=[
            util.CodebaseParameter(
                "codebase",
                label="Build Source",
                repository=util.StringParameter(
                    name="repository",
                    default=DEFAULT_REPO),
                branch=util.StringParameter(
                    name="branch",
                    default="morty"),
                revision=util.StringParameter(
                    name="revision",
                    default="")
            )
        ],
        properties=[
            util.NestedParameter(
                name="options",
                label="Build Options",
                layout="vertical",
                fields=[
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
                ]
            )
        ]
    ),

    schedulers.Nightly(
        name="ntel-nightly",
        builderNames=[
            "ntel-orionlxm",
            "ntel-orionlx-cpx",
            "ntel-orionlx-plus",
            "ntel-orion-io",
            "ntel-qemux86-64",
            "ntel-all",
        ],
        change_filter=util.ChangeFilter(
            codebase=DEFAULT_CODEBASE,
        ),
        codebases=[
            DEFAULT_CODEBASE
        ],
        onlyIfChanged=True,
        properties={
            'clobber': True,
            'cache': True,
            'bbflags': DEFAULT_BBFLAGS,
        },
        hour=22,
    )
]


# BUILDERS
# The 'builders' list defines the Builders, which tell Buildbot how to perform
# a build: what steps, and which workers can execute them.  Note that any
# particular build will only take place on one worker.
c['builders'] = []

git_lock = util.MasterLock("git")


@util.renderer
def CurrentTime(props):
    from datetime import datetime
    import string
    dt = datetime.now()
    dt.replace(microsecond=0)
    dts = string.replace(dt.isoformat(), ':', '.')
    return dts


@util.renderer
def ComputeBuildProperties(props):
    newprops = {}

    newprops['timestamp'] = ts = CurrentTime

    newprops['dest'] = dest = util.Interpolate(
        "/cache/images/%(prop:buildername)s")

    newprops['archive'] = archive = util.Interpolate(
        "%(kw:d)s/%(prop:machine)s.%(kw:t)s.tar.gz", d=dest, t=ts)

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
        lines = [
        ]
        lines.extend(args)
        configstring = '\n'.join(lines)
        conf_file = kw.setdefault('conf_file', 'auto.conf')
        sdkw = {
            'name': 'generate %s' % (conf_file),
            'workerdest': 'conf/%s' % (conf_file),
        }
        steps.StringDownload.__init__(
            self, util.Interpolate(configstring, **kw), **sdkw)


class BitBake(steps.Compile):

    def __init__(self, package):
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
            'descriptionSuffix': package,
            'env': {'ENV': 'environment-ntel', 'BASH_ENV': 'environment-ntel'},
            'flunkOnFailure': True,
            'haltOnFailure': False,
            'name': 'bitbake',
            'timeout': int(os.getenv('LONG_RUN_TIMEOUT', 600)),
            'warningPattern': "^WARNING: ",
        }
        steps.Compile.__init__(self, **kw)


class BitBakeArchive(steps.ShellCommand):

    def __init__(self, **kw):
        if 'machine' in kw:
            self.machine = kw['machine']
        else:
            self.machine = util.Property('machine')
        kw = {
            'command': ['ci-archive.sh',
                        self.machine,
                        util.Property("dest"),
                        util.Property("timestamp")],
            'description': 'archiving',
            'descriptionDone': 'archive',
            'env': {},
            'flunkOnFailure': True,
            'haltOnFailure': False,
            'name': 'archive',
            'env': {'PATH': ['/home/buildbot/', '${PATH}'],
                    'ENV': 'environment-ntel',
                    'BASH_ENV': 'environment-ntel',
                    },
        }
        steps.ShellCommand.__init__(self, **kw)


class BitBakeFactory(util.BuildFactory):

    def __init__(self, *build_steps):
        util.BuildFactory.__init__(self)
        self.addStep(steps.SetProperties(ComputeBuildProperties))
        self.addStep(steps.GitLab(
            repourl=util.Property('repository'),
            branch=util.Property('branch'),
            codebase=util.Property('codebase'),
            mode=util.Interpolate("%(prop:clobber:#?|full|incremental)s"),
            method="clobber",
            locks=[git_lock.access('exclusive')],
            retry=(360, 5)))
        self.addStep(steps.ShellCommand(
                command=["./oebb.sh", "config", util.Property('machine')]
            ))
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
            BitBake("orionlxm-swu-image"),
            BitBake("orionlxm-disk-swu-image"),
            BitBake("orion-headless-image -c populate_sdk"),
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
            BitBake("-c cleanall u-boot-orion-io"),
            BitBake("orion-io-swu-image"),
            BitBake("orion-headless-image -c populate_sdk"),
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
            BitBake("-c cleanall gdk-pixbuf-native librsvg-native gtk-icon-utils-native"),
            BitBake("orionlx-cpx-swu-image"),
            BitBake("orionlx-cpx-disk-swu-image"),
            BitBake("orion-graphical-image -c populate_sdk"),
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
            BitBake("-c cleanall gdk-pixbuf-native librsvg-native gtk-icon-utils-native"),
            BitBake("orionlx-plus-swu-image"),
            BitBake("orion-graphical-image -c populate_sdk"),
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
            BitBake("gdk-pixbuf-native:do_cleanall"),
            BitBake("orion-graphical-image"),
            BitBake("orion-graphical-image -c populate_sdk"),
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
                    " multiconfig:orionlx-plus:gdk-pixbuf-native:do_cleanall"
                    ),
            BitBake(" orion-graphical-image"
                    " multiconfig:orionlx-cpx:orionlx-cpx-swu-image"
                    " multiconfig:orionlx-cpx:orionlx-cpx-disk-swu-image"
                    " multiconfig:orionlx-plus:orionlx-plus-swu-image"
                    " multiconfig:orionlxm:orionlxm-swu-image"
                    " multiconfig:orion-io:orion-io-swu-image"
                    ),
        ),
        properties={
            'machine': 'qemux86-64',
            'repository': DEFAULT_REPO,
            'multiconfig': ' '.join(multiconfig),
        }
    ))
