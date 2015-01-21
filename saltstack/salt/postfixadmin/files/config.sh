#!/bin/bash
set -e

param="configured"
cur_par=$(awk '/^\$CONF\['\'''${parm}'/ { print substr($3, 0, length($3)-1) }' config.inc.php)

echo ${param}
echo ${cur_par}


#parm='configured';
#echo "\$CONF['${parm}'] = {{ salt['pillar.get']('postfixadmin:configured') }};" | sed -i "s/^\(\$CONF\['$parm'\] = \)false/\1'minchia'/"
#
#
#$CONF['configured'] = false;
#$CONF['database_host'] = 'localhost';
#$CONF['database_user'] = 'postfix';
#$CONF['database_password'] = 'postfixadmin';
#$CONF['database_name'] = 'postfix';