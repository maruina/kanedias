<?php
##
## database access settings in php format
## automatically generated from /etc/dbconfig-common/roundcube.conf
## by /usr/sbin/dbconfig-generate-include
## Tue, 06 Jan 2015 18:03:23 +0000
##
## by default this file is managed via ucf, so you shouldn't have to
## worry about manual changes being silently discarded.  *however*,
## you'll probably also want to edit the configuration file mentioned
## above too.
##
$dbuser='{{ salt['pillar.get']('roundcube:db:user') }}';
$dbpass='{{ salt['pillar.get']('roundcube:db:password') }}';
$basepath='';
$dbname='{{ salt['pillar.get']('roundcube:db:database') }}';
$dbserver='{{ salt['pillar.get']('roundcube:db:host') }}';
$dbport='';
$dbtype='mysql';
