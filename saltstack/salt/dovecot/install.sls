{% from 'dovecot/map.jinja' import dovecot with context %}

{% if salt['grains.get']('os_family') == 'RedHat' %}
    {% if salt['grains.get']('os') == 'CentOS' %}
epel_centos_repo:
  pkg.installed:
    - name: epel-release
    {% endif %}
{% endif %}

dovecot_install:
  pkg.installed:
    - pkgs:
      - {{ dovecot.lookup.mysql }}
      - {{ dovecot.lookup.pop3 }}
      - {{ dovecot.lookup.imap }}
      - {{ dovecot.lookup.sieve }}