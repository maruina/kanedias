gitlab_ssl_create_dir:
  file.directory:
    - name: /etc/gitlab/ssl
    - user: root
    - group: root
    - dir_mode: 700
    - recurse:
        - user
        - group
        - mode