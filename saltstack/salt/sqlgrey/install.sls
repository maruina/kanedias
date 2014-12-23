{% from 'sqlgrey/map.jinja' import sqlgrey with context %}

sqlgrey_install:
  pkg.installed:
    - name: {{ sqlgrey.lookup.package }}