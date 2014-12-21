{% from 'openssl/map.jinja' import openssl with context %}

python_openssl_install:
  pkg.installed:
    - name: python-openssl

{% for name, parameters in salt['pillar.get']('openssl:ca').iteritems() %}
    {% if 'self-signed' in parameters['type'] %}
        {% set create_certs_dir = 'create_certs_dir_' ~ name %}
        {% set create_private_dir = 'create_private_dir_' ~ name %}
        {% set generate_self_signed_cert = 'generate_self_signed_cert_' ~ name %}

{{ create_certs_dir }}:
  file.directory:
    - name: {{ parameters['cacert_path'] }}/{{ name }}/certs
    - user: root
    - group: root
    - makedirs: True
    - mode: 600

{{ create_private_dir }}:
  file.directory:
    - name: {{ parameters['cacert_path'] }}/{{ name }}/private
    - user: root
    - group: root
    - makedirs: True
    - mode: 600

{{ generate_self_signed_cert }}:
  cmd.run:
    - name: openssl req -new -x509 -days {{ parameters['days'] }} -nodes -newkey rsa:{{ parameters['bits'] }} -out {{ parameters['cacert_path'] }}/{{ name }}/certs/{{ parameters['CN'] }}.pem -keyout {{ parameters['cacert_path'] }}/{{ name }}/private/{{ parameters['CN'] }}.pem
    - unless: test -f {{ parameters['cacert_path'] }}/{{ name }}/private/{{ parameters['CN'] }}.pem

    {% endif %}
{% endfor %}