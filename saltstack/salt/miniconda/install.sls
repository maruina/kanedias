{% from 'miniconda/map.jinja' import miniconda with context %}

miniconda_download:
  cmd.run:
    - name: wget http://repo.continuum.io/miniconda/Miniconda-latest-Linux-{{ salt['grains.get']('osarch', '') }}.sh -O miniconda.sh
    - unless: test -f miniconda.sh

miniconda_install:
  cmd.run:
    - name: bash miniconda.sh -b -p {{ pillar['miniconda']['path'] }}
    - unless: test -f {{ pillar['miniconda']['path'] }}/bin/conda

miniconda_path:
  file.managed:
    - name: {{ miniconda.lookup.profile_dir }}/miniconda.sh
    - source: salt://miniconda/files/miniconda.sh
    - user: root
    - group: root
    - mode: 644
    - template: jinja

miniconda_reload_profile:
  cmd.run:
    - name: source /etc/profile