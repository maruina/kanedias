from fabric.api import task, execute, env
from vagrant import vagrant_up, vagrant_get_ssh_config, vagrant_destroy
from ubuntu import apt_update
from postgis import postgis_install, postgis_puppet
from ntp import ntp_puppet
from puppet import puppet_install
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
    vagrant_network = config['VAGRANT']['vagrant_network']
    app_config_file = config['PROJECT']['app_config_file']
    env['local_user'] = config['PROJECT']['local_user']
    #execute(vagrant_destroy, vagrant_dir)
    #execute(vagrant_up, vagrant_dir)
    execute(vagrant_get_ssh_config, vagrant_dir, vagrant_network)
    #execute(apt_update)
    #execute(puppet_install)
    #execute(ntp_puppet)
    #execute(postgis_install)
    execute(postgis_puppet, app_config_file)