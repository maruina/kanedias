{% from 'git/map.jinja' import git with context %}

include:
  - git.install

{% for name, parameters in salt['pillar.get']('git:repository').iteritems() %}
  {% set git_state_id = 'git_repo_' ~ name %}
  {% set file_git_id = 'file_git_' ~ name %}

{{ file_git_id }}:
  file.managed:
    - name: /etc/git_keys/{{ parameters['identity'] }}
    - source: salt://git/files/{{ parameters['identity'] }}
    - mode: 600
    - makedirs: True
    - replace: False

{{ git_state_id }}:
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
    {% set git_dir_id = 'dir_git_' ~ name %}

{{ git_dir_id }}:
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