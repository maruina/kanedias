from StringIO import StringIO
from fabric.api import task, sudo, get, roles
from fabric.context_managers import hide


@roles('vagrant', 'db')
@task
def postgis_install():
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