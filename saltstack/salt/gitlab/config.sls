{% from 'gitlab/map.jinja' import gitlab with context %}

gitlab_config:
  file.managed:
    - name: {{ gitlab.lookup.conf_dir }}/gitlab.rb
    - source: salt://gitlab/files/gitlab.rb
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - watch_in:
      - cmd: gitlab_reconfigure