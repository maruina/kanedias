import os
import sys
import math
import time
import boto.ec2
import boto.vpc
from boto.route53.connection import Route53Connection
from fabric.colors import red, green
from fabric.api import run, sudo, cd, put
from fabric.context_managers import settings, env
from netaddr import IPNetwork
from load_config import AWS_KEY, AWS_ID, AMI_LIST, AWS_REGIONS, AMI_USER, REGION, DEFAULT_OS, DEFAULT_SSH_DIR
from utils import find_subnet_nat_public_ip, test_vpc_cidr


def print_all_vpcs_info(aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
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


def build_private_public_vpc(cidr, aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    """
    Create a VPC with one private and one public subnet, in 2 different availability zones
    :param cidr: The CIDR for your VPC; min /16, max /28
    :param aws_id: Amazon Access Key ID
    :param aws_key: Amazon Secret Access Key
    :param region: Target region for the VPC
    :return: Nothing
    """
    pass


def build_ha_vpc(cidr, aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    """
    Create the subnet for the VPC. The creation rule is: number of subnets = number of availability zones + a
    spare zone. For each subnet you have a private subnet and a public + spare subnet
    :param cidr: The CIDR for your VPC; min /16, max /28
    :param aws_id: Amazon Access Key ID
    :param aws_key: Amazon Secret Access Key
    :param region: Target region for the VPC
    :return: Nothing
    """
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    # Exit if a VPC with that CIDR already exists
    if test_vpc_cidr(cidr=cidr, vpc_conn=vpc_conn):
        sys.exit(1)
    else:
        vpc = vpc_conn.create_vpc(cidr_block=cidr)

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


def aws_create_instance(ec2_conn, name, image_id, key_name, type_id, subnet_id, security_group_ids):
    instance_reservation = ec2_conn.run_instances(image_id=image_id, key_name=key_name, instance_type=type_id,
                                                  subnet_id=subnet_id, security_group_ids=[security_group_ids])
    print(instance_reservation)
    instance = instance_reservation.instances[0]
    print(instance)
    instance.add_tag('Name', name)
    # Check if the instance is ready
    print('Waiting for instance to start...')
    status = instance.update()
    while status == 'pending':
        time.sleep(10)
        status = instance.update()
    if status == 'running':
        print(green('New instance {} ready with private IP {}'.format(instance.id, instance.private_ip_address)))
    else:
        print('Instance status: ' + status)
    return instance


def aws_create_global_nat_instance(subnet_id, key_name, env, aws_id=None or AWS_ID, aws_key=None or AWS_KEY,
                                   region=None or REGION):
    """
    Create a single NAT instance in the target subnet
    :param subnet_id:
    :param key_name:
    :param env:
    :param aws_id:
    :param aws_key:
    :param region:
    :return:
    """
    # Retrive subnet
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    subnet = vpc_conn.get_all_subnets(subnet_ids=[subnet_id])[0]
    # Check if there is a NAT Security Group into the VPC
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    security_groups = ec2_conn.get_all_security_groups()
    nat_security_group = [x for x in security_groups if 'NAT_SG' in x.name][0]
    # Create a NAT Security Group. Allow outbound connection and allow inbound SSH
    if not nat_security_group:
        nat_security_group = ec2_conn.create_security_group('NAT_Global_SG', 'NAT Global Security Group',
                                                            vpc_id=subnet.vpc_id)
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

    nat_reservation = ec2_conn.run_instances(image_id=nat_image.id, key_name=nat_key.name, instance_type='t2.micro',
                                             subnet_id=subnet.id, security_group_ids=[nat_security_group.id])
    nat_instance = nat_reservation.instances[0]
    # Check how many NAT instances already running
    nat_instances = ec2_conn.get_all_instances(filters={'tag:Name': 'nat*'})
    nat_instance_name = 'nat.' + str(len(nat_instances) + 1).zfill(3) + '.' + env + '.' +\
                        subnet.availability_zone + '.archondronistics.lan'
    nat_instance.add_tag('Name', nat_instance_name)
    # Check if the instance is ready
    print('Waiting for instance to start...')
    status = nat_instance.update()
    while status == 'pending':
        time.sleep(10)
        status = nat_instance.update()
    if status == 'running':
        print(green('New instance {} ready'.format(nat_instance.id)))
    else:
        print('Instance status: ' + status)

    # Allocate and associate a new Elastic IP
    print('Allocate new Elastic IP')
    new_ip = ec2_conn.allocate_address()
    ec2_conn.associate_address(instance_id=nat_instance.id, public_ip=new_ip.public_ip)
    time.sleep(3)
    nat_instance.update()
    print(green('Instance {} [{}] accessible at {}'.format(nat_instance.tags['Name'], nat_instance.id,
                                                           nat_instance.ip_address)))
    # Disabling Source/Destination Checks
    ec2_conn.modify_instance_attribute(instance_id=nat_instance.id, attribute='sourceDestCheck', value='False')
    # Updating the Main Route Table
    route_table = vpc_conn.get_all_route_tables(filters={'tag:Name': 'Global Private*'})[0]
    vpc_conn.create_route(route_table_id=route_table.id, destination_cidr_block='0.0.0.0/0',
                          instance_id=nat_instance.id)
    #TODO: Test NAT


def spin_saltmaster(subnet_id, key_string, op_system=None or DEFAULT_OS, aws_id=None or AWS_ID, aws_key=None or AWS_KEY,
                    region=None or REGION):
    """
    Spin a salmaster instance in the target subnet
    :param subnet_id: Target subnet
    :param key_string: A string to identify the PEM key you want to use
    :param op_system: The OS you want to install Saltmaster
    :param aws_id: Amazon Access Key ID
    :param aws_key: Amazon Secret Access Key
    :param region: Target VPC region
    :return: Nothing
    """
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    subnet = vpc_conn.get_all_subnets(subnet_ids=[subnet_id])[0]
    vpc = vpc_conn.get_all_vpcs(vpc_ids=subnet.vpc_id)[0]

    # Check if there is a proper Secuirty Group already
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    security_groups = ec2_conn.get_all_security_groups()
    saltmaster_security_group = [x for x in security_groups if 'Saltmaster_SG' in x.name]
    if not saltmaster_security_group:
        print('Creating Saltmaster Security Group...')
        saltmaster_security_group = ec2_conn.create_security_group('Saltmaster_SG', 'Saltmaster Security Group',
                                                                   vpc_id=subnet.vpc_id)
        saltmaster_security_group.add_tag('Name', 'Saltmaster Security Group')
        saltmaster_security_group.authorize(ip_protocol='tcp', from_port=4505, to_port=4506, cidr_ip=vpc.cidr_block)
        saltmaster_security_group.authorize(ip_protocol='tcp', from_port=22, to_port=22, cidr_ip='0.0.0.0/0')
        print('Done')
    else:
        saltmaster_security_group = saltmaster_security_group[0]
        print('Saltmaster Security Group already exists: {}'.format(saltmaster_security_group.id))

    # Check how many Saltmaster instances already running
    saltmaster_reservation = ec2_conn.get_all_instances(filters={'tag:Name': 'saltmaster*'})[0]
    if not saltmaster_reservation:
        saltmaster_name = 'saltmaster.global.' + subnet.availability_zone + '.archondronistics.lan'

        print('New Saltmaster instance name: {}'.format(saltmaster_name))
        print('New Saltmaster OS: {}'.format(op_system))

        saltmaster_key = [x for x in ec2_conn.get_all_key_pairs() if key_string in x.name][0]

        # Run the instance
        saltmaster_instance = aws_create_instance(ec2_conn=ec2_conn, name=saltmaster_name,
                                                  image_id=AMI_LIST[op_system]['regions'][region],
                                                  key_name=saltmaster_key.name, type_id='t2.micro', subnet_id=subnet.id,
                                                  security_group_ids=saltmaster_security_group.id)
    else:
        saltmaster_instance = saltmaster_reservation.instances[0]
        print('Saltmaster instance {} already running'.format(saltmaster_instance.id))

    # Look for the appropriate NAT instance public ip
    nat_public_ip = find_subnet_nat_public_ip(subnet_id=subnet_id, ec2_conn=ec2_conn, vpc_conn=vpc_conn)
    print('Public IP to connect to: {}'.format(nat_public_ip))

    conn_key = DEFAULT_SSH_DIR + saltmaster_instance.key_name + '.pem'
    script = os.path.abspath(os.path.join(os.path.abspath(os.curdir), os.pardir, 'saltstack')) +\
             '/bootstrap_saltmaster.sh'

    with settings(gateway=nat_public_ip, host_string='root@'+saltmaster_instance.private_ip_address, user=AMI_USER[op_system],
                  key_filename=conn_key, forward_agent=True), cd('/root'):
        # run('uname -a')
        put(script, mode=0700)
        run('./bootstrap_saltmaster.sh')