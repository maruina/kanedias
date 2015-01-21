{% from 'gitlab/map.jinja' import gitlab with context %}

gitlab_download:
  cmd.run:
    - name: wget {{ gitlab.lookup.package }}
    - unless: test -f {{ gitlab.lookup.name }}

gitlab_install:
  pkg.installed:
    - sources:
      - gitlab: /root/{{ gitlab.lookup.name }}

gitlab_reconfigure:
  cmd.run:
    - name: gitlab-ctl reconfigure

{% if 'RedHat' in salt['grains.get']('os_family') %}

gitlab_redhat_lokkit:
    cmd.run:
      - name: lokkit -s http -s ssh -s https

{% endif %}