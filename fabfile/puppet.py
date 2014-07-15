from fabric.api import local, env, task, settings, execute, run, sudo
from fabric.context_managers import lcd


def puppet_install():
    run('wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb')
    sudo('dpkg -i puppetlabs-release-precise.deb')
    sudo('apt-get update')
    sudo('apt-get install puppet')