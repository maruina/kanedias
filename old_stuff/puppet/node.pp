node default {
  notify {'I am the default':}

}

node 'vagrant.archon.lan' {
  class { '::ntp':
  servers => [ 'ntp1.inrim.it', 'ntp2.inrim.it'],
  }
  notify {'Hello Vagrant':}
}