{% from 'supervisor/map.jinja' import supervisor with context %}

supervisor_install:
  pkg.installed:
    - name: {{ supervisor.lookup.package }}