import os
import sys
from boto.pyami.config import Config
from fabric.colors import red

# Load the configuration file
if os.path.exists('config.ini'):
    boto_config = Config()
    boto_config.load_credential_file('config.ini')
    if boto_config.items('Credentials'):
        AWS_ID = boto_config.get('Credentials', 'aws_access_key_id')
        AWS_KEY = boto_config.get('Credentials', 'aws_secret_access_key')
        REGION = boto_config.get('Credentials', 'region')
    else:
        print(red('Error: credentials section is missing, abort!'))
        sys.exit(1)
else:
    print(red('Error: configuration file missing, abort!'))
    sys.exit(1)

AWS_REGIONS = {
    'ap-northeast-1': 'Asia Pacific (Tokyo)',
    'ap-southeast-1': 'Asia Pacific (Singapore)',
    'ap-southeast-2': 'Asia Pacific (Sydney)',
    'eu-central-1': 'EU (Frankfurt)',
    'eu-west-1': 'EU (Ireland)',
    'sa-east-1': 'South America (Sao Paulo)',
    'us-east-1': 'US East (N. Virginia)',
    'us-west-1': 'US West (N. California)',
    'us-west-2': 'US West (Oregon)'
}

AMI_LIST = {
    'CentOS': {
        'version': 'CentOS-6 x86_64 with updates',
        'type': 'HVM',
        'regions': {
            'us-east-1': 'ami-c2a818aa',
            'us-west-1': 'ami-57cfc412',
            'us-west-2': 'ami-81d092b1',
            'eu-west-1': 'ami-30ff5c47'
        }
    },
    'Debian': {
        'version': 'Debian x86_64 7.7',
        'type': 'HVM',
        'regions': {
            'us-east-1': 'ami-5ae66932',
            'us-west-1': 'ami-b12e39f4',
            'us-west-2': 'ami-87367eb7',
            'eu-west-1': 'ami-46cc6631'
        }
    },
    'Ubuntu': {
        'version': 'Ubuntu x86_64 12.04 LTS',
        'type': 'HVM with EBS-SSD',
        'regions': {
            'us-east-1': 'ami-34cc7a5c',
            'us-west-1': 'ami-b7515af2',
            'us-west-2': 'ami-0f47053f',
            'eu-west-1': 'ami-6ca1011b',
            'eu-central-1': 'ami-643c0a79'
        }
    }
}

VPC_TAGS = {

}

ENVIRONMENTS = {
    'dev': 'development',
    'tst': 'test',
    'sta': 'staging',
    'prd': 'production'
}