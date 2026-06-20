incus_pkg:
  pkg.installed:
    - name: incus

incus_subuid:
  file.append:
    - name: /etc/subuid
    - text: 'root:1000000:1000000000'

incus_subgid:
  file.append:
    - name: /etc/subgid
    - text: 'root:1000000:1000000000'

incus_service:
  service.running:
    - name: incus.service
    - enable: True
    - require:
      - pkg: incus_pkg
      - file: incus_subuid
      - file: incus_subgid

incus_startup:
  service.enabled:
    - name: incus-startup.service
    - require:
      - pkg: incus_pkg

incus_admin_group:
  group.present:
    - name: incus-admin
    - addusers:
      - i.nebotov
    - require:
      - pkg: incus_pkg
      - user: i.nebotov

incus_init:
  cmd.run:
    - name: incus admin init --minimal
    - unless: 'incus storage list --format csv | grep -q .'
    - require:
      - service: incus_service

incus_https_listener:
  cmd.run:
    - name: incus config set core.https_address :8443
    - unless: '[ "$(incus config get core.https_address)" = ":8443" ]'
    - require:
      - service: incus_service
