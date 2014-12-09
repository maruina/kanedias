{% from 'openssl/map.jinja' import openssl with context %}

openssl_install:
  pkg.installed:
    - name: {{ openssl.lookup.package }}

