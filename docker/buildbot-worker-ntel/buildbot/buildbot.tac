import fnmatch
import os
import sys

from twisted.application import service
from twisted.python.log import FileLogObserver
from twisted.python.log import ILogObserver

from buildbot_worker.bot import Worker

# setup worker
basedir = os.path.abspath(os.path.dirname(__file__))
application = service.Application('buildbot-worker')


application.setComponent(ILogObserver, FileLogObserver(sys.stdout).emit)
# and worker on the same process!
buildmaster_host = os.environ.get("BUILDBOT_MASTER", 'localhost')
port = int(os.environ.get("BUILDBOT_WORKER_PORT", 9989))
workername = os.environ.get("BUILDBOT_WORKER_NTEL", 'docker')
passwd = os.environ.get("BUILDBOT_WORKER_PASSWORD")

# delete the password from the environ so that it is not leaked in the log
blacklist = os.environ.get("BUILDBOT_ENVIRONMENT_BLACKLIST", "BUILDBOT_WORKER_PASSWORD").split(',')
for name in list(os.environ.keys()):
    for toremove in blacklist:
        if fnmatch.fnmatch(name, toremove):
            del os.environ[name]

keepalive = 600
umask = None
maxdelay = 300
allow_shutdown = None

s = Worker(buildmaster_host, port, workername, passwd, basedir,
           keepalive, umask=umask, maxdelay=maxdelay,
           allow_shutdown=allow_shutdown)
s.setServiceParent(application)
