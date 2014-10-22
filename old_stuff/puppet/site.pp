node default {
  notify {'I am the default':}

}

node 'vagrant.archon.lan' {
  include ntp
  include git
  include apt
}


class { '::ntp':
		servers => [ 'ntp1.inrim.it', 'ntp2.inrim.it' ]
}

class { '::apt':
  always_apt_update    => false,
  disable_keys         => undef,
  purge_sources_list   => false,
  purge_sources_list_d => false,
  purge_preferences_d  => false,
  update_timeout       => undef
}

apt::source { 'postgis':
  location   => 'http://apt.postgresql.org/pub/repos/apt/',
  release    => 'precise-pgdg',
  repos      => 'main',
  key        => 'ACCC4CF8',
  key_source => 'http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc',
}

# Install PostgreSQL 9.3 server from the PGDG repository
class {'postgresql::globals':
  version => '9.3',
  manage_package_repo => true,
  encoding => 'UTF8'
}

class { 'postgresql::server':
  ensure                     => 'present',
  ip_mask_deny_postgres_user => '0.0.0.0/32',
  ip_mask_allow_all_users    => '0.0.0.0/0',
  listen_addresses           => '*',
  ipv4acls                   => ['local all all trust', 'host all all 192.168.33.0/24 trust'],
  postgres_password          => '',
}

postgresql::server::role { 'vagrant':
  password_hash => postgresql_password('vagrant', 'vagrant'),
  superuser => true
}

postgresql::server::db { 'archon-dev':
    user     => 'archondb',
    password => postgresql_password('archondb', 'archonpwd')
}

postgresql::server::db { 'archon-stag':
    user     => 'archondb',
    password => postgresql_password('archondb', 'archonpwd')
}

postgresql::server::db { 'archon-prod':
    user     => 'archondb',
    password => postgresql_password('archondb', 'archonpwd')
}