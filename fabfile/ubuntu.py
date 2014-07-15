from StringIO import StringIO
from fabric.api import local, task, run, env, sudo, get
from fabric.operations import reboot
from fabric.tasks import execute
from fabric.context_managers import lcd, hide


@task
def apt_update():
    with hide('stdout'):
        sudo('apt-get update')
        sudo('export DEBIAN_FRONTEND=noninteractive')
        sudo('apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade')
        reboot()
