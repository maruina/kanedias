import os
import sys
from boto.pyami.config import Config
from boto.route53.connection import Route53Connection
from fabric.colors import red, green


def aws_load_credentials():
    # Load the configuration
    if os.path.exists('config.ini'):
        boto_config = Config()
        boto_config.load_credential_file('config.ini')
        if boto_config.items('Credentials'):
            aws_id = boto_config.get('Credentials', 'aws_access_key_id')
            aws_key = boto_config.get('Credentials', 'aws_secret_access_key')
        else:
            print(red('Credentials section is missing, abort!'))
            sys.exit(1)
    else:
        print(red('Configuration file missing, abort!'))
        sys.exit(1)
    return aws_id, aws_key


def aws_create_hosted_zone(domain_name, caller_ref=None, comment=''):
    aws_id, aws_key = aws_load_credentials()
    route53 = Route53Connection(aws_access_key_id=aws_id, aws_secret_access_key=aws_key)

    hosted_zones = route53.get_all_hosted_zones()['ListHostedZonesResponse']['HostedZones']
    for hosted_zone in hosted_zones:
        if domain_name in hosted_zone['Name']:
            print(red('Error: hosted zone already exist'))
            sys.exit(1)
    else:
        route53.create_hosted_zone(domain_name=domain_name, caller_ref=caller_ref, comment=comment)
        print(green('Ok: Hosted zone {} created'.format(domain_name)))