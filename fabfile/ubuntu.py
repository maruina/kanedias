from StringIO import StringIO
from fabric.api import local, task, run, env, sudo, get
from fabric.tasks import execute
from fabric.context_managers import lcd, hide


@task
def apt_update():
    with hide('stdout'):
        sudo('apt-get update')
        sudo('apt-get -y upgrade')