{% from 'miniconda/map.jinja' import miniconda with context %}

venv_build_packages:
  pkg.installed:
    - pkgs:
      - {{ miniconda.lookup.gcc }}

{% for name, parameters in salt['pillar.get']('miniconda:virtualenv').iteritems() %}
    {% set venv_id = 'venv_' ~ name %}

{{ venv_id }}:
  cmd.run:
    - name: {{ pillar['miniconda']['path'] }}/bin/conda create -n {{ name }} --yes python={{ parameters['python'] }} pip
    - unless: test -d {{ pillar['miniconda']['path'] }}/envs/{{ name }}

    {% if 'anaconda_requirements' in parameters %}
        {% set install_areq = 'install_areq_' ~ name %}

{{ install_areq }}:
  cmd.run:
    - name: {{ pillar['miniconda']['path'] }}/bin/conda install -n {{ name }} --yes --file
        {{ parameters['anaconda_requirements'] }}

    {% endif %}
    {% if 'requirements' in parameters %}
        {% set install_req = 'install_req_' ~ name %}

{{ install_req }}:
  cmd.run:
    - name: {{ pillar['miniconda']['path'] }}/envs/{{ name }}/bin/pip install -r {{ parameters['requirements'] }}
    - env:
        - PATH: $PATH:/usr/pgsql-9.3/bin:/usr/bin

    {% endif %}
{% endfor %}