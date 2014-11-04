import os
import sys
import math
import boto.ec2
import boto.vpc
from boto.pyami.config import Config
from boto.route53.connection import Route53Connection
from fabric.colors import red, green
from netaddr import IPNetwork


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


def aws_ec2_run_instance(ami_id, key, instance_type=None, security_group=None):
    if not os.path.exists(key):
        print(red('Error, ssh key not found'))
        sys.exit(1)
    else:
        aws_id, aws_key = aws_load_credentials()
        conn = boto.ec2.connect_to_region('us-east-1', aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
        # Red Hat Enterprise 6.5: ami-11125e21 no-micro
        # Ubuntu 12.04 LTS amd_64: ami-7d69244d
        # CentOS 6.5 amd_64: ami-a9de9c99
        conn.run_instances(ami_id, key_name=key)


def aws_check_vpc_exists(parameter, mode):

    aws_id, aws_key = aws_load_credentials()
    conn = boto.vpc.connect_to_region('us-east-1', aws_access_key_id=aws_id, aws_secret_access_key=aws_key)

    if 'by_id' in mode:
        vpcs = conn.get_all_vpcs(vpc_ids=parameter)
        if vpcs:
            return [vpc.id for vpc in vpcs]
        else:
            return None
    elif 'by_cidr':
        vpcs = conn.get_all_vpcs()
        vpcs_cidrs = [vpc.cidr_block for vpc in vpcs if parameter in vpc.cidr_block]
        if vpcs_cidrs:
            return vpcs_cidrs
        else:
            return None
    else:
        print(red('Error: invalid mode. Choose between "by_ib" and "by_cidr".'))
        sys.exit(1)


def aws_create_vpc(cidr, tags=None, tenancy=None, dry_run=False):
    aws_id, aws_key = aws_load_credentials()

    # Check if the VPC already exists
    if aws_check_vpc_exists(cidr, 'by_cidr'):
        print(red('Error, VPC already exists'))
    else:
        aws_id, aws_key = aws_load_credentials()
        conn = boto.vpc.connect_to_region('us-east-1', aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
        vpc = conn.create_vpc(cidr_block=cidr, instance_tenancy=tenancy, dry_run=dry_run)[0]
        print(green(vpc))
        if tags:
            for tag in tags:
                vpc.add_tag(tag)


def aws_subnet_vpc(vpc_id):
    """
    Create the subnet for the VPC. The creation rule is: number of subnets = number of availability zones + a
    spare zone. For each subnet you have a private subnet and a public + spare subnet
    :param vpc_id: the VPC to subnet
    """
    aws_id, aws_key = aws_load_credentials()
    vpc_conn = boto.vpc.connect_to_region('us-east-1', aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    vpc = vpc_conn.get_all_vpcs(vpc_ids=vpc_id)[0]

    # Get all the availability zones from the region
    region = str(vpc.region).rsplit(':')[-1]
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    av_zones = ec2_conn.get_all_zones()

    # At least one subnet per zone + 1 spare
    subnets_desired_number = len(av_zones) + 1
    vpc_mask_bits = int(vpc.cidr_block.split('/')[1])
    vpc_network = IPNetwork(vpc.cidr_block)
    subnets_maks_bits = vpc_mask_bits + int(math.ceil(math.log(subnets_desired_number, 2)))
    vpc_subnets = list(vpc_network.subnet(subnets_maks_bits))

    # Create the subnets
    for counter, zone in enumerate(av_zones):
        zone_string = str(zone).split(':')[1]
        # Create the Private subnet
        private_subnet, public_and_spare_subnet = list(vpc_subnets[counter].subnet(subnets_maks_bits + 1))
        subnet = vpc_conn.create_subnet(vpc_id=vpc.id, cidr_block=str(private_subnet),
                                        availability_zone=zone_string)
        subnet.add_tag('Name', 'Private AZ ' + zone_string)

        # Create the Public and Spare subnet
        public_subnet, spare_subnet = list(public_and_spare_subnet.subnet(public_and_spare_subnet.prefixlen + 1))
        subnet = vpc_conn.create_subnet(vpc_id=vpc.id, cidr_block=str(public_subnet),
                                        availability_zone=zone_string)
        subnet.add_tag('Name', 'Public AZ ' + zone_string)
        subnet = vpc_conn.create_subnet(vpc_id=vpc.id, cidr_block=str(spare_subnet),
                                        availability_zone=zone_string)
        subnet.add_tag('Name', 'Spare AZ ' + zone_string)


def aws_add_tags(vpc_id):
    aws_id, aws_key = aws_load_credentials()
    conn = boto.vpc.connect_to_region('us-east-1', aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    vpc = conn.get_all_vpcs(vpc_ids=vpc_id)[0]

    tags = {
        'Name': 'Global network',
        'Owner': 'ruio'
    }

    for key, value in tags.iteritems():
        vpc.add_tag(key, value)