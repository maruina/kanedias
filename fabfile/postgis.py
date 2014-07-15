from StringIO import StringIO
from fabric.api import task, sudo, get, roles, put, env, run
from fabric.context_managers import hide
from puppet import puppet_install_module
from jinja2 import Environment, FileSystemLoader
import os


@roles('vagrant')
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

    with hide('stdout'):
        sudo('apt-get update')
        sudo('apt-get install -y --force-yes postgresql-9.3 postgresql-9.3-postgis postgresql-contrib')


@roles('vagrant')
@task
def postgis_puppet(config_file):
    print config_file
    postgis_params = {}
    with open(config_file, 'r') as env_file:
        for line in env_file.readlines():
            if line.startswith('DB_NAME') and len(line.strip().split('=')) == 2:
                env_var = line.strip().split('=')
                postgis_params[env_var[0].lower()] = env_var[1]
            if line.startswith('DB_USERNAME') and len(line.strip().split('=')) == 2:
                env_var = line.strip().split('=')
                postgis_params[env_var[0].lower()] = env_var[1]
            if line.startswith('DB_PASSWORD') and len(line.strip().split('=')) == 2:
                env_var = line.strip().split('=')
                postgis_params[env_var[0].lower()] = env_var[1]

    postgis_params['vagrant_network'] = env.vagrant_network
    postgis_params['local_user'] = env.local_user

    module_name = 'puppetlabs-postgresql'
    puppet_install_module(module_name)

    postgis_env = Environment(loader=FileSystemLoader('templates'))
    template = postgis_env.get_template('postgis.html')
    output = template.render(postgis_params)

    output_file = os.getcwd() + '/puppet/postgis.pp'

    with open(output_file, 'w') as fw:
        fw.write(output)
    fw.close()

    put(output_file, '/tmp/')

    sudo('puppet apply /tmp/postgis.pp')


@task
def postgis_add_extensions():
    with hide('stdout'):
        run("psql -U vagrant -d 'archon' -c 'CREATE EXTENSION postgis;'")
        run("psql -U vagrant -d 'archon' -c 'CREATE EXTENSION postgis_topology;'")