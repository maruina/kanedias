from fabric.api import local, task, run, env, sudo, get, put
from jinja2 import Environment, FileSystemLoader
import os


@task
def ntp_puppet():
    ntp_params = {
        'ntp_server_1': 'ntp1.inrim.it',
        'ntp_server_2': 'ntp2.inrim.it'
    }

    ntp_env = Environment(loader=FileSystemLoader('templates'))
    template = ntp_env.get_template('ntp.html')
    output = template.render(ntp_params)

    output_file = os.getcwd() + '/puppet/ntp.pp'

    with open(output_file, 'w') as fw:
        fw.write(output)
    fw.close()

    put(output_file, '/tmp/provisioning/')

    