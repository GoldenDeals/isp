{% from "components/base/map.jinja" import base with context %}

i.nebotov:
  user.present:
    - home: /home/i.nebotov
    - shell: {{ base.shell }}
    - createhome: true
    - groups:
      - {{ base.admin_group }}

i_nebotov_authorized_keys:
  ssh_auth.present:
    - user: i.nebotov
    - source: salt://components/base/files/i.nebotov.pub
    - require:
      - user: i.nebotov

i_nebotov_sudoers:
  file.managed:
    - name: /etc/sudoers.d/i-nebotov
    - contents: 'i.nebotov ALL=(ALL:ALL) NOPASSWD: ALL'
    - mode: '0440'
    - user: root
    - group: root
    - check_cmd: /usr/sbin/visudo -c -f
    - require:
      - user: i.nebotov
