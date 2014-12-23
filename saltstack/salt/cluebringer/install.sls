{% from 'cluebringer/map.jinja' import cluebringer with context %}

cluebringer_install:
  pkg.installed:
    - pkgs:
      - {{ cluebringer.lookup.package }}
      - {{ cluebringer.lookup.mysql }}