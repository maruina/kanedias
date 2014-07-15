class { '::ntp':
		servers => [ 'ntp1.inrim.it', 'ntp2.inrim.it' ]
}
include '::ntp'