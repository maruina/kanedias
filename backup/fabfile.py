import os
import sys
import ConfigParser
from fabric.colors import red, green
from fabric.api import sudo, get, task
from fabric.context_managers import settings

config = ConfigParser.ConfigParser()
if os.path.exists('config.ini'):
    config.read('config.ini')
else:
    print(red('Error: config file not found!'))
    sys.exit(1)


@task
def wordpress_backup():
    for website in config.sections():
        ssh_server = config.get(website, 'ssh_server')
        ssh_user = config.get(website, 'ssh_user')
        ssh_key = config.get(website, 'ssh_key')
        database = config.get(website, 'database')
        mysql_root_password = config.get(website, 'mysql_root_password')
        wordpress_remote_folder = config.get(website, 'wordpress_remote_folder')
        backup_folder = config.get(website, 'backup_folder')

        website_folder = os.path.join(backup_folder, website)
        if not os.path.exists(website_folder):
            os.mkdir(website_folder)
            print("Directory {} created".format(website_folder))
        else:
            print("Warning: directory {} is not empty, I will save in it".format(website_folder))

        with settings(host_string=ssh_user + '@' + ssh_server, user=ssh_user, key_filename=ssh_key, warn_only=True):
            sudo('mysqldump -u root --password=' + mysql_root_password + ' ' + database + ' | gzip > /root/wp.db.gz')
            sudo('tar -zcvf /root/wp.tar.gz ' + wordpress_remote_folder)
            get(remote_path='/root/wp.db.gz', local_path=website_folder)
            get(remote_path='/root/wp.tar.gz', local_path=website_folder)
            sudo('rm -rf /root/wp.db.gz')
            sudo('rm -rf /root/wp.tar.gz')
            print(green('Ok: webiste {} backup complete!'.format(website)))