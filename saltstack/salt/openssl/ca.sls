{% from 'openssl/map.jinja' import openssl with context %}

python_openssl_install:
  pkg.installed:
    - name: python-openssl

{% for name, parameters in salt['pillar.get']('openssl:ca').iteritems() %}
    {% if 'self-signed' in parameters['type'] %}
        {% set generate_self_signed_cert = 'generate_self_signed_cert_' ~ name %}

{{ generate_self_signed_cert }}:
  module.run:
    - name: tls.create_self_signed_cert
    - tls_dir: {{ name }}
    - CN: {{ parameters['CN'] }}
    - C: {{ parameters['C'] }}
    - ST: {{ parameters['ST'] }}
    - L: {{ parameters['L'] }}
    - O: {{ parameters['OU'] }}
    - OU: {{ parameters['OU'] }}
    - emailAddress: {{ parameters['emailAddress'] }}
    - cacert_path: {{ parameters['cacert_path'] }}
    - digest: {{ parameters['digest'] }}

    {% endif %}
{% endfor %}
