from fabric.api import local, env, task, settings, execute
from fabric.context_managers import lcd


@task
def vagrant_up(vagrant_dir):
    with lcd(vagrant_dir), settings(warn_only=True):
        vagrant_status = [line for line in local('vagrant status', capture=True).splitlines()]
        if any('running' in s for s in vagrant_status):
            pass
        else:
            local('vagrant up')


@task
def vagrant_halt(vagrant_dir):
    with lcd(vagrant_dir), settings(warn_only=True):
        vagrant_status = [line for line in local('vagrant status', capture=True).splitlines()]
        if any('poweroff' in s for s in vagrant_status):
            pass
        else:
            local('vagrant halt')


@task
def vagrant_destroy(vagrant_dir):
    execute(vagrant_halt, vagrant_dir)
    with lcd(vagrant_dir), settings(warn_only=True):
        local('vagrant destroy --force')


@task
def vagrant_get_ssh_config(vagrant_dir):
    with lcd(vagrant_dir):
        result = dict(line.split() for line in local('vagrant ssh-config', capture=True).splitlines())
        env.hosts = ['%s:%s' % (result['HostName'], result['Port'])]
        env.user = result['User']
        env.key_filename = result['IdentityFile']


