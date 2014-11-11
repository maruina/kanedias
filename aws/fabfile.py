import os
import sys
import math
import boto.ec2
import boto.vpc
from boto.route53.connection import Route53Connection
from fabric.colors import red, green
from netaddr import IPNetwork
from load_config import AWS_KEY, AWS_ID, AMI_LIST, AWS_REGIONS, REGION


def aws_print_all_vpc_info(aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    vpcs = vpc_conn.get_all_vpcs()
    print('You have {} VPC in region {} [{}]'.format(len(vpcs), AWS_REGIONS[region], region))
    for vpc in vpcs:
        print(green('VPC: {} - CIDR: {}'.format(vpc.id, vpc.cidr_block)))
        subnet_filter = {'vpcId': vpc.id}
        subnets = [x for x in vpc_conn.get_all_subnets(filters=subnet_filter) if 'Name' in x.tags]
        if subnets:
            for subnet in subnets:
                print('\tSubnet: {} - CIDR: {} - {}'.format(subnet.id, subnet.cidr_block, subnet.tags['Name']))



def aws_create_vpc(cidr, aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION,
                   tags=None, tenancy=None, dry_run=False):

    # Check if the VPC already exists
    if aws_check_vpc_exists(cidr, 'by_cidr'):
        print(red('Error, VPC already exists'))
    else:
        conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)



def aws_build_ha_vpc(cidr, aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    """
    Create the subnet for the VPC. The creation rule is: number of subnets = number of availability zones + a
    spare zone. For each subnet you have a private subnet and a public + spare subnet
    :param vpc_id: the VPC to subnet
    """
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    vpcs = [x for x in vpc_conn.get_all_vpcs() if cidr in x.cidr_block]
    if vpcs:
        print(red('Warning: The following VPCs have the same CIDR you want to create'))
        for vpc in vpcs:
            print('VPC: {}'.format(vpc.id))
        while True:
            user_input = raw_input('Do you want to continue? [Y/n]: ')
            if 'n' in str(user_input).lower():
                print('Quitting...')
                sys.exit(1)
            elif 'Y' in str(user_input).upper():
                print('Continue')
                break
            else:
                print('Wrong answer, use [Y/n]')

    # Get all the availability zones from the region
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


def aws_create_internet_gateway(vpc_id, aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    """
    Check if the VPC has an Internet Gateway. If not, the function creates one and attach it to the target VPC
    :param vpc_id: Target VPC ID
    :param aws_id: Amazon Access Key ID
    :param aws_key: Amazon Secret Access Key
    :param region: Target VPC region
    :return:
    """
    # Check if the VPC has an internet gateway already
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    vpc_internet_gateway = vpc_conn.create_internet_gateway()
    vpc_conn.attach_internet_gateway(vpc_internet_gateway.id, vpc_id=vpc_id)
    vpc_internet_gateway.add_tag("Name", "Global Internet Gateway")


def aws_make_subnet_public(vpc_id, ig_id, aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    vpc = vpc_conn.get_all_vpcs(vpc_ids=vpc_id)[0]
    ig = vpc_conn.get_all_internet_gateways(internet_gateway_ids=ig_id)[0]

    # Create a new route table for the public subnet
    public_route_table = vpc_conn.create_route_table(vpc_id=vpc_id)
    public_route_table.add_tag('Name', 'Global Public Route Table')
    vpc_conn.create_route(public_route_table.id, '0.0.0.0/0', ig.id)

    subnet_filter = {'vpcId': vpc_id}
    subnets = vpc_conn.get_all_subnets(filters=subnet_filter)

    for subnet in subnets:
        if 'Public' in subnet.tags['Name']:
            vpc_conn.associate_route_table(route_table_id=public_route_table.id, subnet_id=subnet.id)


def aws_add_tags(vpc_id, tags, aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    vpc = conn.get_all_vpcs(vpc_ids=vpc_id)[0]

    for key, value in tags.iteritems():
        vpc.add_tag(key, value)


def aws_create_nat_instance(subnet_id, key_name, aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    """
    Create a NAT instance in the target subnet
    :param vpc_id:
    :param subnet:
    :param aws_id:
    :param aws_key:
    :param region:
    :return:
    """
    # Check if there is a NAT Security Group into the VPC.
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    security_groups = ec2_conn.get_all_security_groups()
    nat_security_group = [x for x in security_groups if 'NAT_SG' in x.name][0]
    # Create a NAT Security Group. Allow outbound connection and allow inbound SSH
    if not nat_security_group:
        nat_security_group = ec2_conn.create_security_group('NAT_SG', 'NAT Security Group Recommended Rules',
                                                            vpc_id=subnet_id.vpc_id)
        nat_security_group.tag('Name', 'NAT Security Group')
        nat_security_group.authorize(ip_protocol='tcp', from_port=22, to_port=22, cidr_ip='0.0.0.0/0')

    # Create a NAT instance
    filters = {
        'architecture': 'x86_64',
        'virtualization-type': 'hvm',
        'block-device-mapping.volume-type': 'gp2',
        "owner-alias": "amazon",
        "name": "amzn-ami-vpc-nat*"
    }
    nat_image = ec2_conn.get_all_images(filters=filters)[0]
    nat_key = [x for x in ec2_conn.get_all_key_pairs() if key_name in x.name][0]

    print(nat_security_group.id)

    nat_instance = ec2_conn.run_instances(image_id=nat_image.id, key_name=nat_key.name, instance_type='t2.micro',
                                          subnet_id=subnet_id, security_group_ids=[nat_security_group.id])
    # Allocate a new Elastic IP
    new_ip = ec2_conn.allocate_address()
    ec2_conn.associate_address(instance_id=nat_instance.instances, public_ip=new_ip.public_ip)
