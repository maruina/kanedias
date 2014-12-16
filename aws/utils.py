import time
from fabric.colors import red, green
from netaddr import IPNetwork


def find_subnet_nat_instance(subnet_id, ec2_conn, vpc_conn):
    """
    Find the NAT instance for the given subnet
    :param subnet_id: The desired subnet
    :param ec2_conn: A boto.ec2.connect_to_region() object
    :param vpc_conn: A boto.vpc.connect_to_region() object
    :return: The NAT instance public IP
    """
    routes = vpc_conn.get_all_route_tables()
    subnet_route = [r for r in routes for a in r.associations if a.subnet_id and subnet_id in a.subnet_id][0]
    instance_id = [r for r in subnet_route.routes if '0.0.0.0/0' in r.destination_cidr_block][0].instance_id
    reservation = ec2_conn.get_all_instances(instance_ids=instance_id)[0]
    instance = reservation.instances[0]
    return instance


def find_ssh_user(instance_id, ec2_conn):
    """
    Find the SSH user for login with for the given instance
    :param instance_id:
    :param ec2_conn:
    :return:
    """
    reservation = ec2_conn.get_all_instances(instance_ids=instance_id)[0]
    instance = reservation.instances[0]
    image = ec2_conn.get_all_images(image_ids=instance.image_id)[0]
    if 'Amazon' in image.description:
        return 'ec2-user'
    elif 'CentOS' in image.description:
        return 'root'
    else:
        return 'ubuntu'


def test_vpc_cidr(cidr, vpc_conn):
    """
    Test if already exists a VPC with the desired CIDR
    :param cidr: The desired CIDR
    :param vpc_conn: A boto.vpc.connect_to_region() object
    :return: True if the VPC exists, otherwise False
    """
    vpcs = [x for x in vpc_conn.get_all_vpcs() if cidr in x.cidr_block]
    if vpcs:
        print(red('Error: the following VPCs have the same CIDR you want to create'))
        for vpc in vpcs:
            print('\tVPC: {}'.format(vpc.id))
        return vpcs
    else:
        return None


def calculate_public_private_cidr(vpc_cidr, av_zones):
    """
    Divide the CIDR in a Public and Private subnet
    :param vpc_cidr: The desired CIDR
    :param av_zones: A boto.ec2.get_all_zones() object containing all the AZ
    :return: A dictionary contains the subnet, its CIDR and its AZ
    """
    subnet_tags = ['Public', 'Private']
    vpc_mask_bits = int(vpc_cidr.split('/')[1])
    vpc_network = IPNetwork(vpc_cidr)
    subnets_maks_bits = vpc_mask_bits + 1
    vpc_subnets = list(vpc_network.subnet(subnets_maks_bits))
    subnet_dict = {}
    for counter, subnet in enumerate(subnet_tags):
        subnet_dict[subnet] = {
            'Network': vpc_subnets[counter],
            'Zone': av_zones[counter]
        }
    return subnet_dict


def get_zone_id(route53_conn, domain_name):
    """
    Find the Zone ID based on the Zone Name
    :param route53_conn:
    :param domain_name:
    :return: The Zone ID otherwise None
    """
    zone = route53_conn.get_hosted_zone_by_name(hosted_zone_name=domain_name)
    if not zone:
        print(red("Error, domain {} does not exist".format(domain_name)))
        return None
    else:
        zone_id = zone['GetHostedZoneResponse']['HostedZone']['Id'].replace('/hostedzone/', '')
        return zone_id


def create_instance(ec2_conn, name, image_id, key_name, type_id, subnet_id, security_group_ids):
    """
    Create an EC2 instance based on the given parameters
    :param ec2_conn:
    :param name:
    :param image_id:
    :param key_name:
    :param type_id:
    :param subnet_id:
    :param security_group_ids:
    :return:
    """
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


def test_instance_exists(instance_id, ec2_conn):
    # Check if the instance exists
    reservations = ec2_conn.get_all_instances(instance_ids=[instance_id])
    if not reservations:
        print(red('Error, instance {} does not exitst'.format(instance_id)))
        return None
    else:
        instance = reservations[0].instances[0]
        return instance