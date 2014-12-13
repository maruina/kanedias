{% from 'git/map.jinja' import git with context %}

include:
  - git.install

{% for name, parameters in salt['pillar.get']('git:repository').iteritems() %}
  {% set git_repo = 'git_repo_' ~ name %}
  {% set git_ssh_key = 'git_ssh_key_' ~ name %}

{{ git_ssh_key }}:
  file.managed:
    - name: /etc/git_keys/{{ parameters['identity'] }}
    - source: salt://git/files/{{ parameters['identity'] }}
    - mode: 600
    - makedirs: True
    - replace: False

{{ git_repo }}:
  git.latest:
    - name: {{ name }}
    - rev: {{ parameters['rev'] }}
    - target: {{ parameters['target'] }}
    - identity: /etc/git_keys/{{ parameters['identity'] }}
    - force: {{ parameters['force'] }}
    - force_checkout: {{ parameters['force_checkout'] }}
    - require:
      - sls: git.install

  {% if parameters['user'] %}
    {% set git_dir_mode = 'git_dir_mode_' ~ name %}

{{ git_dir_mode }}:
  file.directory:
    - name: {{ parameters['target'] }}
    - user: {{ parameters['user'] }}
    - group: {{ parameters['group'] }}
    - dir_mode: {{ parameters['dir_mode'] }}
    - recurse:
        - user
        - group
        - mode

    {% endif %}
{% endfor %}