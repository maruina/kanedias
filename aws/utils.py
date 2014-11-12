
def find_subnet_nat_public_ip(subnet_id, ec2_conn, vpc_conn):
    routes = vpc_conn.get_all_route_tables()
    subnet_route = [r for r in routes for a in r.associations if a.subnet_id and subnet_id in a.subnet_id][0]
    internet_eni_id = [r for r in subnet_route.routes if '0.0.0.0/0' in r.destination_cidr_block][0].interface_id
    internet_eni = ec2_conn.get_all_network_interfaces(network_interface_ids=[internet_eni_id])[0]
    return internet_eni.publicIp
