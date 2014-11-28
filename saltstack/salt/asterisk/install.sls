{% from 'asterisk/map.jinja' import asterisk with context %}

{% if salt['grains.get']('os_family') == 'RedHat' %}
asterisk_add_user:
   user.present:
     - name: {{ asterisk.lookup.user }}
     - home: /home/{{ asterisk.lookup.user }}
     - password: $6$HSrIGIrm03Rf44W5$e80QCst381JmcppQTRBoxZNXsvOycazUhZr7mKMgarIFI3ErX8/KBlYzEjZjuFpp46Rwbi0FNB.KcWgArMqOz/

asterisk_install_prerequisites:

{% endif %}
