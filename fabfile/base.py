from StringIO import StringIO
from fabric.api import local, task, run, env, sudo, get
from fabric.tasks import execute
from fabric.context_managers import lcd, hide


@task
def uptime():
    run('uptime')


@task
def postgis_start():
    with hide('stdout'):
        sudo('/etc/init.d/postgresql start')


@task
def postgis_stop():
    with hide('stdout'):
        sudo('/etc/init.d/postgresql stop')


@task
def postgis_restart():
    with hide('stdout'):
        sudo('/etc/init.d/postgresql restart')


#execute(uptime)
#execute(apt_update)
#execute(apt_add_postgis)
