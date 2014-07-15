from configobj import ConfigObj
import os
import sys
from fabric.api import execute
from fabfile import vagrant


if __name__ == '__main__':

    if os.path.exists('config.ini'):
        print 'Configuration file found\n'
        config = ConfigObj('config.ini')
    else:
        print 'Configuration file missing, abort'
        sys.exit(1)

    print 'Project name: {}'.format(config['PROJECT']['name'])

    for env in config['PROJECT']['environments']:
        if 'dev' in env:
            print 'Development environment to be deployed to {} via {}'.format(config['DEV']['where'],
                                                                               config['DEV']['how'])
        if 'staging' in env:
            print 'Staging environment to be deployed to {} via {}'.format(config['STAGING']['where'],
                                                                           config['STAGING']['how'])
        if 'production' in env:
            print 'Production environment to be deployed to {} via {}'.format(config['PRODUCTION']['where'],
                                                                              config['PRODUCTION']['how'])

    vagrant_file = config['VAGRANT']['vagrant_file']
    execute(vagrant.vagrant_up, vagrant_file)
