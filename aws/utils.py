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
        return True
    else:
        return False


def split_cidr(cidr, subnets):
    """
    Divide the
    :param cidr: The desired CIDR
    :param subnets: A list contain the name of the subnets. For example ['Public', 'Private'] or
    ['Public', 'Private', 'Spare']
    :return: A dictionary contains the subnet and its cidr
    """


