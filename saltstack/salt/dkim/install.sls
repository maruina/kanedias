{% from 'dkim/map.jinja' import dkim with context %}

dkim_install:
  pkg.installed:
    - pkgs:
      - {{ dkim.lookup.package }}
      - {{ dkim.lookup.tools }}