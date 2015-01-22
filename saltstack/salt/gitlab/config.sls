{% from 'gitlab/map.jinja' import gitlab with context %}

{% if 'verified' in salt['pillar.get']('gitlab:web:ssl_type') %}

gitlab_create_key_dir:
  file.directory:
    - name: {{ gitlab.lookup.conf_dir }}/ssl
    - user: root
    - group: root
    - dir_mode: 700
    - makedirs: True
    - recurse:
        - user
        - group
        - mode

gitlab_install_crt:
  file.managed:
    - name: {{ gitlab.lookup.conf_dir }}/ssl/{{ salt['pillar.get']('gitlab:web:hostname') }}.crt
    - source: salt://gitlab/files/ssl.crt
    - user: root
    - group: root
    - mode: 600
    - template: jinja

gitlab_install_key:
  file.managed:
    - name: {{ gitlab.lookup.conf_dir }}/ssl/{{ salt['pillar.get']('gitlab:web:hostname') }}.key
    - source: salt://gitlab/files/ssl.key
    - user: root
    - group: root
    - mode: 600
    - template: jinja

{% endif %}

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
    - context:
        ssl_dir: {{ gitlab.lookup.conf_dir }}/ssl