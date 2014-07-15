from StringIO import StringIO
from fabric.api import local, task, run, env, sudo, get
from fabric.tasks import execute
from fabric.context_managers import lcd, hide


@task
def uptime():
    run('uptime')


@task
def apt_update():
    with hide('stdout'):
        sudo('apt-get update')
        sudo('apt-get upgrade')


@task
def apt_add_postgis():
    source_list = "/etc/apt/sources.list"
    repo = "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main"

    fd = StringIO()
    get(source_list, fd)
    content = fd.getvalue()

    if repo not in content:
    # Add the repository
        with hide('stdout'):
            sudo('echo ' + repo + ' >> /etc/apt/sources.list')
    else:
        with hide('stdout'):
            sudo('apt-get update')

        sudo('apt-get install -y --force-yes postgresql-9.3 postgresql-9.3-postgis postgresql-contrib')


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
