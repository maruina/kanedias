from fabric.api import local, env, task, settings, execute, run, sudo
from fabric.context_managers import hide


@task
def puppet_install():
    with hide('stdout'):
        run('wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb')
        sudo('dpkg -i puppetlabs-release-precise.deb')
        sudo('apt-get update')
        sudo('apt-get install -y --force-yes puppet')


@task
def puppet_install_module(module):
    with hide('stdout'):
        if module in run('puppet module list'):
            pass
        else:
            sudo('puppet module install ' + module + ' --modulepath=/etc/puppet/modules')