{% from 'miniconda/map.jinja' import miniconda with context %}

{% for name, parameters in salt['pillar.get']('miniconda:virtualenv').iteritems() %}
    {% set venv_id = 'venv_' ~ name %}

{{ venv_id }}:
  cmd.run:
    - name: conda create -p {{ parameters['directory'] }}/{{ name }} --yes python={{ parameters['python'] }} pip
    - unless: test -d {{ parameters['directory'] }}

    {% if parameters['anaconda_requirements'] %}
        {% set install_areq = 'install_areq_' ~ name %}

{{ install_areq }}:
  cmd.run:
    - name: conda install -n {{ parameters['directory'] }}/{{ name }} -- file {{ parameters['anaconda_requirements'] }}

    {% endif %}
    {% if parameters['requirements'] %}
        {% set install_req = 'install_req_' ~ name %}
{{ install_req }}:
  cmd.run:
    - name: {{ parameters['directory'] }}/{{ name }}/bin/pip install -r {{ parameters['requirements'] }}

    {% endif %}
    {% if parameters['packages'] %}
        {% set install_packages = 'install_pkgs_' ~ name %}
{{ install_packages }}:
  cmd.run:
    - name: {{ parameters['directory'] }}/{{ name }}/bin/pip install {{ parameters['packages'] }}

    {% endif %}
{% endfor %}