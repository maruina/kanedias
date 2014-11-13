import math
from fabric.colors import red
from netaddr import IPNetwork


def find_subnet_nat_public_ip(subnet_id, ec2_conn, vpc_conn):
    """
    Find the NAT instance for the given subnet
    :param subnet_id: The desired subnet
    :param ec2_conn: A boto.ec2.connect_to_region() object
    :param vpc_conn: A boto.vpc.connect_to_region() object
    :return: The NAT instance public IP
    """
    routes = vpc_conn.get_all_route_tables()
    subnet_route = [r for r in routes for a in r.associations if a.subnet_id and subnet_id in a.subnet_id][0]
    internet_eni_id = [r for r in subnet_route.routes if '0.0.0.0/0' in r.destination_cidr_block][0].interface_id
    internet_eni = ec2_conn.get_all_network_interfaces(network_interface_ids=[internet_eni_id])[0]
    return internet_eni.publicIp


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
    Divide the CIDR according the subnets number
    :param vpc_cidr: The desired CIDR
    :param av_zones: A boto.ec2.get_all_zones() object containing all the AZ
    :return: A dictionary contains the subnet and its cidr
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

