{% from 'vim/map.jinja' import vim with context %}

vim_install:
  pkg.installed:
    - name: {{ vim.lookup.package }}