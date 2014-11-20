import os
import sys
import time
import ConfigParser
import boto.ec2
import boto.vpc
import boto.route53
import boto.route53.record
from socket import gethostbyname
from fabric.colors import red, green
from fabric.api import run, sudo, cd, put, get, task
from fabric.context_managers import settings
from load_config import AWS_KEY, AWS_ID, AMI_LIST, AWS_REGIONS, AMI_USER, REGION, DEFAULT_OS, DEFAULT_SSH_DIR,\
    DEFAULT_FILE_DIR, DEFAULT_INTERNAL_DOMAIN
from utils import test_vpc_cidr, calculate_public_private_cidr, find_ssh_user, find_subnet_nat_instance, get_zone_id,\
    create_instance


@task
def print_vpcs_info(aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    """
    Print all VPCs and Subnets
    :param aws_id: Amazon Access Key ID
    :param aws_key: Amazon Secret Access Key
    :param region: Target region for the VPC
    """
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


@task
def build_private_public_vpc(cidr, key_user, domain_name, aws_id=None or AWS_ID, aws_key=None or AWS_KEY,
                             region=None or REGION):
    """
    Create a VPC with one private and one public subnet, in 2 different availability zones chosed at random
    :param cidr: The CIDR for your VPC; min /16, max /28
    :param key_user: The name of the AWS PEM key user
    :param domain_name: the domain name for your internal DNS resolution in the DHCP option
    :param aws_id: Amazon Access Key ID
    :param aws_key: Amazon Secret Access Key
    :param region: Target region for the VPC
    :return: Nothing
    """
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    av_zones = ec2_conn.get_all_zones()

    #Check if a VPC with that CIDR already exists
    vpcs = test_vpc_cidr(cidr=cidr, vpc_conn=vpc_conn)
    if vpcs:
        print(red('You have a VPC withing the desired subnet already, aborting...'))
        sys.exit(1)
    else:
        # Create the VPC
        vpc = vpc_conn.create_vpc(cidr_block=cidr)
        vpc.add_tag('Name', 'Public/Private VPC')
        vpc_conn.modify_vpc_attribute(vpc_id=vpc.id, enable_dns_support=True)
        vpc_conn.modify_vpc_attribute(vpc_id=vpc.id, enable_dns_hostnames=True)
        print('VPC {} in {} ({}) created'.format(vpc.id, AWS_REGIONS[vpc.region.name], vpc.region.name))

    # Create the DHCP Option
    dhcp_options = vpc_conn.create_dhcp_options(domain_name=domain_name, domain_name_servers=['AmazonProvidedDNS'],
                                                ntp_servers=[
                                                    gethostbyname('0.amazon.pool.ntp.org'),
                                                    gethostbyname('1.amazon.pool.ntp.org'),
                                                    gethostbyname('2.amazon.pool.ntp.org'),
                                                    gethostbyname('3.amazon.pool.ntp.org')
                                                ])
    dhcp_options.add_tag('Name', domain_name + ' internal')
    vpc_conn.associate_dhcp_options(dhcp_options_id=dhcp_options.id, vpc_id=vpc.id)
    print('DHCP Options {} created'.format(dhcp_options.id))

    # Create an Internet Gateway
    internet_gateway = vpc_conn.create_internet_gateway()
    print('Internet Gateway {} created'.format(internet_gateway.id))
    vpc_conn.attach_internet_gateway(internet_gateway.id, vpc_id=vpc.id)
    internet_gateway.add_tag("Name", "Internet Gateway " + vpc.tags['Name'])

    # Divide the VPC in subnet_dict
    subnetting = calculate_public_private_cidr(vpc_cidr=cidr, av_zones=av_zones)
    subnet_dict = {}
    for key, item in subnetting.iteritems():
        subnet_dict[key] = vpc_conn.create_subnet(vpc_id=vpc.id, cidr_block=item['Network'].cidr,
                                                  availability_zone=item['Zone'].name)
        subnet_dict[key].add_tag('Name', key + '-' + item['Zone'].name)

    # Tag the Main Route Table
    vpc_filter = {'vpcId': vpc.id}
    main_route_table = vpc_conn.get_all_route_tables(filters=vpc_filter)[0]
    main_route_table.add_tag('Name', 'Main Route Table')

    # Create the Public Route Table
    public_route_table = vpc_conn.create_route_table(vpc_id=vpc.id)
    print('Public Route Table {} created'.format(public_route_table.id))
    public_route_table.add_tag('Name', 'Public Route Table')
    vpc_conn.create_route(route_table_id=public_route_table.id, destination_cidr_block='0.0.0.0/0',
                          gateway_id=internet_gateway.id)
    print('Public Route created')

    # Associate the public subnet
    vpc_conn.associate_route_table(route_table_id=public_route_table.id, subnet_id=subnet_dict['Public'].id)

    # Create a SSH key for the region
    key_name = key_user + '-' + vpc.region.name
    keys = [x for x in ec2_conn.get_all_key_pairs() if key_name in x.name]
    if keys:
        print('SSH key {} already exists'.format(key_name))
        key = keys[0]
    else:
        key = ec2_conn.create_key_pair(key_name=key_name)
        print('SSH key {} created'.format(key.name))
        key.save(DEFAULT_SSH_DIR)
        print('SSH key downloaded in {}'.format(DEFAULT_SSH_DIR))

    # Create a NAT instance
    nat_instance = spin_nat(subnet_id=subnet_dict['Public'].id, key_name=key.name, env_tag='prd')
    print('NAT instance {} created'.format(nat_instance.id))

    # Create Private Route Table
    private_route_table = vpc_conn.create_route_table(vpc_id=vpc.id)
    print('Private Route Table {} created'.format(private_route_table.id))
    private_route_table.add_tag('Name', 'Private Route Table')
    vpc_conn.create_route(route_table_id=private_route_table.id, destination_cidr_block='0.0.0.0/0',
                          instance_id=nat_instance.id)
    print('Private Route created')

    # Associate the private subnet
    vpc_conn.associate_route_table(route_table_id=private_route_table.id, subnet_id=subnet_dict['Private'].id)

    print(green('VPC succesfully created!'))
    print(red('Remember to create manually the Private Hosted Zone {}'.format(domain_name)))


@task
def spin_nat(subnet_id, key_name, env_tag, aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    """
    Spin a NAT instance in the target subnet
    """
    # Retrive subnet
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    subnet = vpc_conn.get_all_subnets(subnet_ids=[subnet_id])[0]
    vpc = vpc_conn.get_all_vpcs(vpc_ids=[subnet.vpc_id])[0]
    # Check if there is a suitable NAT Security Group into the VPC
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    security_groups = ec2_conn.get_all_security_groups()
    nat_security_groups = [x for x in security_groups if 'NAT_SG' in x.name]
    # Create a NAT Security Group. Allow outbound connection and allow inbound SSH
    if not nat_security_groups:
        nat_security_group = ec2_conn.create_security_group('NAT_Global_SG', 'NAT Global Security Group',
                                                            vpc_id=subnet.vpc_id)
        nat_security_group.add_tag('Name', 'NAT Security Group')
        nat_security_group.authorize(ip_protocol='tcp', from_port=22, to_port=22, cidr_ip='0.0.0.0/0')
        nat_security_group.authorize(ip_protocol='tcp', from_port=80, to_port=80, cidr_ip=vpc.cidr_block)
        nat_security_group.authorize(ip_protocol='tcp', from_port=443, to_port=443, cidr_ip=vpc.cidr_block)
        nat_security_group.authorize(ip_protocol='icmp', from_port=-1, to_port=-1, cidr_ip=vpc.cidr_block)
    else:
        nat_security_group = nat_security_groups[0]

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
    nat_instance_name = 'nat.' + str(len(nat_instances) + 1).zfill(3) + '.' + env_tag + '.' +\
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
    # route_table = vpc_conn.get_all_route_tables(filters={'tag:Name': 'Global Private*'})[0]
    # vpc_conn.create_route(route_table_id=route_table.id, destination_cidr_block='0.0.0.0/0',
    #                       instance_id=nat_instance.id)
    #TODO: Test NAT
    return nat_instance


@task
def spin_saltmaster(subnet_id, key_user, op_system=None or DEFAULT_OS, aws_id=None or AWS_ID, aws_key=None or AWS_KEY,
                    region=None or REGION):
    """
    Spin a salmaster instance in the target subnet
    :param subnet_id: Target subnet
    :param key_user: A string to identify the PEM key you want to use
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
        saltmaster_security_group.authorize(ip_protocol='icmp', from_port=-1, to_port=-1, cidr_ip=vpc.cidr_block)
        saltmaster_security_group.authorize(ip_protocol='tcp', from_port=22, to_port=22, cidr_ip='0.0.0.0/0')
        print('Done')
    else:
        saltmaster_security_group = saltmaster_security_group[0]
        print('Saltmaster Security Group already exists: {}'.format(saltmaster_security_group.id))

    # Check how many Saltmaster instances already running
    saltmaster_reservations = ec2_conn.get_all_instances(filters={'tag:Name': 'saltmaster*'})
    if not saltmaster_reservations:
        saltmaster_name = 'saltmaster.' + subnet.availability_zone + '.archondronistics.lan'

        print('New Saltmaster instance name: {}'.format(saltmaster_name))
        print('New Saltmaster OS: {}'.format(op_system))

        saltmaster_key = [x for x in ec2_conn.get_all_key_pairs() if key_user in x.name][0]

        # Run the instance
        saltmaster_instance = create_instance(ec2_conn=ec2_conn, name=saltmaster_name,
                                              image_id=AMI_LIST[op_system]['regions'][region],
                                              key_name=saltmaster_key.name, type_id='t2.micro', subnet_id=subnet.id,
                                              security_group_ids=saltmaster_security_group.id)
    else:
        saltmaster_instance = saltmaster_reservations[0].instances[0]
        print('Saltmaster instance {} already running'.format(saltmaster_instance.id))

    # Look for the appropriate NAT instance public ip
    nat_instance = find_subnet_nat_instance(subnet_id=subnet_id, ec2_conn=ec2_conn, vpc_conn=vpc_conn)
    print('Public IP to connect to: {}'.format(nat_instance.ip_address))

    conn_key = DEFAULT_SSH_DIR + saltmaster_instance.key_name + '.pem'
    salt_script_folder = os.path.abspath(os.path.join(os.path.abspath(os.curdir), os.pardir, 'saltstack'))
    bootstrap_script = salt_script_folder + '/bootstrap_saltmaster.sh'

    with settings(gateway=nat_instance.ip_address, host_string='root@'+saltmaster_instance.private_ip_address, user=AMI_USER[op_system],
                  key_filename=conn_key, forward_agent=True), cd('/root'):
        # run('uname -a')
        put(bootstrap_script, mode=0700)
        run('./bootstrap_saltmaster.sh')
        run('service iptables stop')


@task
def spin_instance(instance_tag, env_tag, subnet_id, key_name, security_group, op_system=None or 'CentOS',
                  instance_type=None or 't2.micro', internal_domain=None or DEFAULT_INTERNAL_DOMAIN,
                  aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    """
    Spin a generic instance
    :param instance_tag:
    :param env_tag:
    :param subnet_id:
    :param key_name:
    :param aws_id:
    :param aws_key:
    :param region:
    :return:
    """
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    subnet = vpc_conn.get_all_subnets(subnet_ids=[subnet_id])[0]
    vpc = vpc_conn.get_all_vpcs(vpc_ids=subnet.vpc_id)[0]

    security_groups = ec2_conn.get_all_security_groups(filters={'description': security_group.upper() + '*'})
    if not security_groups:
        print('You specified a security group that not exists, I will create it')
        # Create a new security group based on the tag
        instance_security_group = ec2_conn.create_security_group(security_group.upper() + '_SG',
                                                                 security_group.upper() + ' Security Group',
                                                                 vpc_id=subnet.vpc_id)
        instance_security_group.add_tag('Name', security_group.upper() + ' Security Group')
        instance_security_group.authorize(ip_protocol='icmp', from_port=-1, to_port=-1, cidr_ip=vpc.cidr_block)
        instance_security_group.authorize(ip_protocol='tcp', from_port=22, to_port=22, cidr_ip='0.0.0.0/0')
        if 'WEB' in instance_tag.upper():
            instance_security_group.authorize(ip_protocol='tcp', from_port=80, to_port=80, cidr_ip='0.0.0.0/0')
            instance_security_group.authorize(ip_protocol='tcp', from_port=443, to_port=443, cidr_ip='0.0.0.0/0')
        if 'MTA' in instance_tag.upper():
            instance_security_group.authorize(ip_protocol='tpc', from_port=587, to_port=587, cidr_ip='0.0.0.0/0')
            instance_security_group.authorize(ip_protocol='tcp', from_port=993, to_port=993, cidr_ip='0.0.0.0/0')
            instance_security_group.authorize(ip_protocol='tcp', from_port=995, to_port=995, cidr_ip='0.0.0.0/0')
        print('Security group {} created'.format(instance_security_group.id))
    else:
        # Use the secuirty group
        if len(security_groups) > 1:
            print(red('Error, there is more than one security group based on your choice. Be more specific'))
            for sg in security_groups:
                print('\t{} ({})'.format(sg.description, sg.id))
            sys.exit(1)
        else:
            instance_security_group = security_groups[0]
            print("Security group {} selected".format(instance_security_group.id))

    keys = [k for k in ec2_conn.get_all_key_pairs() if key_name in k.name]
    if not keys:
        print(red('Error, there is no key with the string {}. Be more specific'.format(key_name)))
        sys.exit(1)
    elif len(keys) > 2:
        print(red('Error, there is more than one key based on your choice. Be more specific'))
        for k in keys:
            print('\t{}'.format(k.name))
        sys.exit(1)
    else:
        instance_key = keys[0]
        print('Key {} selected'.format(instance_key.name))

    # How many instance of this type already running?
    instances = ec2_conn.get_all_instances(filters={'tag:Name': instance_tag + '*'})
    # Instance name: web.prd.001.eu-west-1a.example.com
    instance_name = instance_tag + '.' + env_tag + '.' + str(len(instances) + 1).zfill(3) + '.' +\
                    subnet.availability_zone + '.' + DEFAULT_INTERNAL_DOMAIN

    print('Creating instance {}'.format(instance_name))

    instance = create_instance(ec2_conn=ec2_conn, name=instance_name,
                               image_id=AMI_LIST[op_system]['regions'][region],
                               key_name=instance_key.name,
                               type_id=instance_type, subnet_id=subnet.id,
                               security_group_ids=instance_security_group.id)

    # Check if the subnet is Public or Private
    if 'Private' in subnet.tags['Name']:
        print("Instance in private subnet with IP {}".format(instance.private_ip_address))
    elif 'Public' in subnet.tags['Name']:
        elastic_ips = ec2_conn.get_all_addresses()
        if len(elastic_ips) > 5:
            print(red("You don't have any Elastic IP available"))
            print("Your public instance is without a public IP")
        else:
            new_ip = ec2_conn.allocate_address()
            ec2_conn.associate_address(instance_id=instance.id, public_ip=new_ip.public_ip)
            time.sleep(3)
            instance.update()
            print(green("Instance {} [{}] accessible at {}".format(instance_name, instance.id,
                                                                   instance.ip_address)))

    # Add the DNS entry
    route53_conn = boto.route53.connect_to_region(region_name=region, aws_access_key_id=aws_id,
                                                  aws_secret_access_key=aws_key)
    zone_id = get_zone_id(route53_conn=route53_conn, domain_name=internal_domain)
    if not zone_id:
        print(red("Error, can't find the domain {}".format(internal_domain)))
        print("Instance spinnded successfully but the DNS record creation failed")
        sys.exit(1)
    else:
        zone_changes = boto.route53.record.ResourceRecordSets(route53_conn, zone_id)
        a_record = zone_changes.add_change(action='CREATE', name=instance_name, type='A')
        a_record.add_value(instance.private_ip_address)
        result = zone_changes.commit()
        result.update()
        while 'PENDING' in result.update():
            print("Propagating DNS record...")
            time.sleep(5)

    print(green("Instance {} spinned!".format(instance.id)))


@task
def install_salt(instance_id, aws_id=None or AWS_ID, aws_key=None or AWS_KEY, region=None or REGION):
    """
    Install salt minion on target instance_id. Assumpition: only one Salt Master per VPC
    :param instance_id:
    :param aws_id:
    :param aws_key:
    :param region:
    :return:
    """
    # Check if the instance exists
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    reservations = ec2_conn.get_all_instances(instance_ids=[instance_id])
    if not reservations:
        print(red('Error, instance {} does not exitst'.format(instance_id)))
        sys.exit(1)
    else:
        instance = reservations[0].instances[0]

    instance_name = instance.tags['Name']
    instance_ssh_key = DEFAULT_SSH_DIR + instance.key_name + '.pem'
    instance_ssh_user = find_ssh_user(instance_id=instance.id, ec2_conn=ec2_conn)

    print('Installing salt on instance {} ({})'.format(instance_name, instance.id))

    # Find the saltmaster
    saltmaster_reservations = ec2_conn.get_all_instances(filters={'tag:Name': 'saltmaster*'})
    if not saltmaster_reservations:
        print(red('Error, saltmaster does not exists in this region'))
        sys.exit(1)
    else:
        saltmaster = saltmaster_reservations[0].instances[0]
        saltmaster_ssh_key = DEFAULT_SSH_DIR + saltmaster.key_name + '.pem'
        saltmaster_private_ip = saltmaster.private_ip_address
        saltmaster_ssh_user = find_ssh_user(instance_id=saltmaster.id, ec2_conn=ec2_conn)

    # Find the NAT parameters
    nat_instance = find_subnet_nat_instance(subnet_id=instance.subnet_id, ec2_conn=ec2_conn, vpc_conn=vpc_conn)
    if not nat_instance:
        print(red('Error, NAT instance for instance {} not found'.format(instance.id)))
        sys.exit(1)
    else:
        nat_ssh_user = find_ssh_user(instance_id=nat_instance.id, ec2_conn=ec2_conn)

    # Test if salt is already installed
    with settings(gateway=nat_instance.ip_address, host_string=instance_ssh_user + '@' + instance.private_ip_address,
                  user=nat_ssh_user, key_filename=instance_ssh_key, forward_agent=True, warn_only=True):
        result = sudo('command -v salt-call')
        if result == 0:
            print(green('Salt already installed on instance {} ({})'.format(instance_name, instance.id)))
            sys.exit(0)
        else:
            print('Installing salt')

            salt_script_folder = os.path.abspath(os.path.join(os.path.abspath(os.curdir), os.pardir, 'saltstack'))
            bootstrap_script = salt_script_folder + '/bootstrap_saltminion.sh'

            # Generate a Salt Master accepted key and download it if you don't have it
            if os.path.isfile(DEFAULT_FILE_DIR + instance_name + '.pub') and \
                    os.path.isfile(DEFAULT_FILE_DIR + instance_name + '.pem'):
                print('Key already generated')
            else:
                with settings(gateway=nat_instance.ip_address, host_string=saltmaster_ssh_user + '@' +
                        saltmaster_private_ip, user=nat_ssh_user, key_filename=saltmaster_ssh_key, forward_agent=True):
                    sudo('salt-key --gen-keys=' + instance_name)
                    sudo('cp ' + instance_name + '.pub /etc/salt/pki/master/minions/')
                    sudo('mv /etc/salt/pki/master/minions/' + instance_name + '.pub /etc/salt/pki/master/minions/' +
                         instance_name)
                    get('/root/' + instance_name + '.pem', DEFAULT_FILE_DIR)
                    get('/root/' + instance_name + '.pub', DEFAULT_FILE_DIR)
                    print('Minion key generated and downloaded in {}'.format(DEFAULT_FILE_DIR))

            # Add this line otherwise SSH connection fails
            time.sleep(5)

            # Connect to the instance, bootstrap salt and install the keys
            with settings(gateway=nat_instance.ip_address, host_string=instance_ssh_user + '@' +
                    instance.private_ip_address, user=nat_ssh_user, key_filename=instance_ssh_key, forward_agent=True):
                put(local_path=bootstrap_script, remote_path='/root/', mode=0700, use_sudo=True)
                sudo('/root/bootstrap_saltminion.sh')
                sudo('service salt-minion stop')
                sudo('mv /etc/salt/pki/minion/minion.pem /etc/salt/pki/minion/minion.pem.bkp')
                sudo('mv /etc/salt/pki/minion/minion.pub /etc/salt/pki/minion/minion.pub.bkp')
                sudo('echo ' + instance_name + ' > /etc/salt/minion_id')
                put(local_path=DEFAULT_FILE_DIR + instance_name + '.pem',
                    remote_path='/etc/salt/pki/minion/' + instance_name + '.pem', use_sudo=True)
                put(local_path=DEFAULT_FILE_DIR + instance_name + '.pub',
                    remote_path='/etc/salt/pki/minion/' + instance_name + '.pub', use_sudo=True)
                sudo('mv /etc/salt/pki/minion/' + instance_name + '.pem' + ' /etc/salt/pki/minion/minion.pem')
                sudo('mv /etc/salt/pki/minion/' + instance_name + '.pub' + ' /etc/salt/pki/minion/minion.pub')
                sudo('service salt-minion start')

                # Test if salt can communicate with the master
                with settings(warn_only=True):
                    if sudo('salt-call state.highstate') == 0:
                        print(green('Salt succesfully installed!'))
                    else:
                        print(red('Error, cannot execute salt-call'))


def nuke_instance():
    pass


@task
def update_salt_files(instance_id, dest_dir=None or '/srv', aws_id=None or AWS_ID, aws_key=None or AWS_KEY,
                      region=None or REGION):

    # Check if the instance exists
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    reservations = ec2_conn.get_all_instances(instance_ids=[instance_id])
    if not reservations:
        print(red('Error, instance {} does not exitst'.format(instance_id)))
        sys.exit(1)
    else:
        instance = reservations[0].instances[0]

    instance_ssh_key = DEFAULT_SSH_DIR + instance.key_name + '.pem'
    instance_ssh_user = find_ssh_user(instance_id=instance.id, ec2_conn=ec2_conn)

    # Find the NAT parameters
    nat_instance = find_subnet_nat_instance(subnet_id=instance.subnet_id, ec2_conn=ec2_conn, vpc_conn=vpc_conn)
    if not nat_instance:
        print(red('Error, NAT instance for instance {} not found'.format(instance.id)))
        sys.exit(1)
    else:
        nat_ssh_user = find_ssh_user(instance_id=nat_instance.id, ec2_conn=ec2_conn)

    with settings(gateway=nat_instance.ip_address, host_string=instance_ssh_user + '@' + instance.private_ip_address,
                  user=nat_ssh_user, key_filename=instance_ssh_key, forward_agent=True):
        salt_files_folder = os.path.abspath(os.path.join(os.path.abspath(os.curdir), os.pardir, 'saltstack'))
        sudo("rm -rf /srv/salt")
        sudo("rm -rf /srv/pillar")
        put(local_path=salt_files_folder + '/salt', remote_path=dest_dir, use_sudo=True)
        put(local_path=salt_files_folder + '/pillar', remote_path=dest_dir, use_sudo=True)
        sudo("salt '*' saltutil.refresh_pillar")

    print(green("Salt files updated"))


@task
def backup_salt_master(dest_dir=None or DEFAULT_FILE_DIR, aws_id=None or AWS_ID, aws_key=None or AWS_KEY,
                       region=None or REGION):

    # Check if the instance exists
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    reservations = ec2_conn.get_all_instances(filters={'name': 'saltmaster*'})
    if not reservations:
        print(red("Error, can't find any instance with name saltmaster"))
        sys.exit(1)
    else:
        instance = reservations[0].instances[0]

    instance_ssh_key = DEFAULT_SSH_DIR + instance.key_name + '.pem'
    instance_ssh_user = find_ssh_user(instance_id=instance.id, ec2_conn=ec2_conn)

    backup_folder = dest_dir + instance.id + '_salt_backup'

    if not os.path.exists(backup_folder):
        os.mkdir(backup_folder)
        print("Directory {} created".format(backup_folder))
    else:
        print("Warning: directory {} is not empty, I will save in it".format(backup_folder))

    # Find the NAT parameters
    nat_instance = find_subnet_nat_instance(subnet_id=instance.subnet_id, ec2_conn=ec2_conn, vpc_conn=vpc_conn)
    if not nat_instance:
        print(red('Error, NAT instance for instance {} not found'.format(instance.id)))
        sys.exit(1)
    else:
        nat_ssh_user = find_ssh_user(instance_id=nat_instance.id, ec2_conn=ec2_conn)

    with settings(gateway=nat_instance.ip_address, host_string=instance_ssh_user + '@' + instance.private_ip_address,
                  user=nat_ssh_user, key_filename=instance_ssh_key, forward_agent=True):
        get(remote_path='/etc/salt', local_path=backup_folder)

    print(green("Salt master backup complete!"))


@task
def restore_wordpress(instance_id, section, mysql_root_pass, mysql_db, www_user, aws_id=None or AWS_ID,
                      aws_key=None or AWS_KEY, region=None or REGION):
    """
    Restorce a wordpress_backup() to the target instance
    :param instance_id:
    :param section:
    :param mysql_root_pass:
    :param mysql_db:
    :param www_user:
    :param aws_id:
    :param aws_key:
    :param region:
    :return:
    """
    config = ConfigParser.ConfigParser()

    ini_folder = os.path.abspath(os.path.join(os.path.abspath(os.curdir), os.pardir, 'backup'))
    ini_file = ini_folder + '/config.ini'

    if os.path.exists(ini_file):
        config.read(ini_file)
    else:
        print(red('Error: config file not found!'))
        sys.exit(1)

    backup_folder = config.get(section, 'backup_folder')
    domain_folder = os.path.join(backup_folder, section)

    # Check if the instance exists
    vpc_conn = boto.vpc.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    ec2_conn = boto.ec2.connect_to_region(region_name=region, aws_access_key_id=aws_id, aws_secret_access_key=aws_key)
    reservations = ec2_conn.get_all_instances(instance_ids=[instance_id])
    if not reservations:
        print(red('Error, instance {} does not exitst'.format(instance_id)))
        sys.exit(1)
    else:
        instance = reservations[0].instances[0]

    instance_ssh_key = DEFAULT_SSH_DIR + instance.key_name + '.pem'
    instance_ssh_user = find_ssh_user(instance_id=instance.id, ec2_conn=ec2_conn)

    # Find the NAT parameters
    nat_instance = find_subnet_nat_instance(subnet_id=instance.subnet_id, ec2_conn=ec2_conn, vpc_conn=vpc_conn)
    if not nat_instance:
        print(red('Error, NAT instance for instance {} not found'.format(instance.id)))
        sys.exit(1)
    else:
        nat_ssh_user = find_ssh_user(instance_id=nat_instance.id, ec2_conn=ec2_conn)

    with settings(gateway=nat_instance.ip_address, host_string=instance_ssh_user + '@' + instance.private_ip_address,
                  user=nat_ssh_user, key_filename=instance_ssh_key, forward_agent=True):
        put(local_path=domain_folder + '/wp.db.gz', remote_path='/root/wp.db.gz', use_sudo=True)
        put(local_path=domain_folder + '/wp.tar.gz', remote_path='/root/wp.tar.gz', use_sudo=True)
        with settings(warn_only=True):
            sudo('mkdir /var/www')
        sudo('mkdir /var/www/' + section)
        sudo('tar xvfz /root/wp.tar.gz -C /var/www/' + section)
        sudo('chown -R ' + www_user + ':' + www_user + '/var/www/' + section)
        sudo('chmod -R 755' + www_user + ':' + www_user + '/var/www/' + section)
        sudo('chmod -R 755' + www_user + ':' + www_user + '/var/www/' + section)
        sudo('tar zxvf /root/wp.db.gz')
        sudo('mysqldump -u root --password=' + mysql_root_pass + ' ' + mysql_db + ' < /root/wp.db')

    print(green("Ok, wordpress restore complete!"))

