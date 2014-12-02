{% from 'git/map.jinja' import git with context %}

git_install:
  pkg.installed:
    - name: {{ git.lookup.package }}
