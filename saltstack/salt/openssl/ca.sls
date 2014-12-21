{% from 'openssl/map.jinja' import openssl with context %}

python_openssl_install:
  pkg.installed:
    - name: python-openssl

{% for name, parameters in salt['pillar.get']('openssl:ca').iteritems() %}
    {% if 'self-signed' in parameters['type'] %}
        {% set generate_self_signed_cert = 'generate_self_signed_cert_' ~ name %}

{{ generate_self_signed_cert }}:
  cmd.run:
    - name: openssl req -new -x509 -days {{ parameters['days'] }} -nodes -newkey rsa:{{ parameters['bits'] }} -out {{ parameters['cacert_path'] }}/{{ name }}/certs/{{ parameters['CN'] }}.pem -keyout {{ parameters['cacert_path'] }}/{{ name }}/private/{{ parameters['CN'] }}.pem
    - unless: test -d {{ parameters['cacert_path'] }}/{{ name }}

    {% endif %}
{% endfor %}