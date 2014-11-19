

# {% for database in salt['pillar.get']('mysql:database', []) %}
# {% set state_id = 'mysql_db_' ~ loop.index0 %}