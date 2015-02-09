{% from 'asterisk/map.jinja' import asterisk with context %}

asterisk_add_group:
   group.present:
     - name: {{ asterisk.lookup.user }}

asterisk_add_user:
   user.present:
     - name: {{ asterisk.lookup.user }}
     - gid_from_name: True
     - createhome: False
     - shell: /bin/false

{#asterisk_create_dir:#}
{#  file.directory:#}
{#    - name: {{ salt['pillar.get']('asterisk:source_dir') }}#}
{#    - user: {{ asterisk.lookup.user }}#}
{#    - group: {{ asterisk.lookup.user }}#}
{#    - dir_mode: 744#}
{#    - makedirs: True#}
{#    - recurse:#}
{#        - user#}
{#        - group#}
{#        - mode#}

asterisk_install_prereq:
  pkg.installed:
    - pkgs:
      - {{ asterisk.lookup.gcc }}
      - {{ asterisk.lookup.gcc_cpp }}
      - {{ asterisk.lookup.make }}
      - {{ asterisk.lookup.wget }}
      - {{ asterisk.lookup.libxml2_devel }}
      - {{ asterisk.lookup.ncurses_devel }}
      - {{ asterisk.lookup.openssl_devel }}
      - {{ asterisk.lookup.libuuid_devel }}
      - {{ asterisk.lookup.libjansson_devel }}
      - {{ asterisk.lookup.sqlite3_devel }}

asterisk_install:
  cmd.script:
    - name: install.sh
    - source: salt://asterisk/files/install.sh
    - user: root
    - group: root
    - template: jinja
    - context:
      username: {{ asterisk.lookup.user }}
