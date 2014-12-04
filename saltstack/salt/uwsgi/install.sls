{% if salt['pillar.get']('uwsgi:install_lts') %}

uwsgi_install_lts:
  cmd.run:
    {% if salt['pillar.get']('uwsgi:virtualenv') %}
    - name: {{ salt['pillar.get']('uwsgi:uwsgi_conf:virtualenv') }}/bin/pip install http://projects.unbit.it/downloads/uwsgi-lts.tar.gz
    {% else %}
    - name: pip install http://projects.unbit.it/downloads/uwsgi-lts.tar.gz
    {% endif %}

{% else %}

uwsgi_install_latest:
  cmd.run:
    {% if salt['pillar.get']('uwsgi:uwsgi_conf:virtualenv') %}
    - name: {{ salt['pillar.get']('uwsgi:uwsgi_conf:virtualenv') }}/bin/pip install uwsgi
    {% else %}
    - name: pip install uwsgi
    {% endif %}

{% endif %}