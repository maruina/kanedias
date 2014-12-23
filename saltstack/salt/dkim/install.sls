{% from 'dkim/map.jinja' import dkim with context %}

dkim_install:
  pkg.installed:
    - name: {{ dkim.lookup.package }}