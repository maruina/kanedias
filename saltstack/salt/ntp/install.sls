{% from 'ntp/map.jinja' import ntp with context %}

ntp_install:
  pkg.installed:
    - name: {{ ntp.lookup.package }}
