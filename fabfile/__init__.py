from fabric.api import task, execute, env
from vagrant import vagrant_up, vagrant_get_ssh_config, vagrant_destroy
from ubuntu import apt_update
from configobj import ConfigObj
import os
import sys


def read_config():
    if os.path.exists('config.ini'):
        print 'Configuration file found\n'
        config = ConfigObj('config.ini')
        return config
    else:
        print 'Configuration file missing, abort'
        sys.exit(1)


@task
def vagrant_deploy():
    config = read_config()
    vagrant_dir = config['VAGRANT']['vagrant_dir']
    execute(vagrant_destroy, vagrant_dir)
    execute(vagrant_up, vagrant_dir)
    execute(vagrant_get_ssh_config, vagrant_dir)
    execute(apt_update)