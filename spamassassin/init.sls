#!jinja|yaml

{% from 'spamassassin/defaults.yaml' import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('spamassassin:lookup')) %}

spamassassin:
  pkg:
    - installed
    - pkgs: {{ datamap.pkgs }}
  service:
    - {{ datamap.service.ensure|default('running') }}
    - name: {{ datamap.service.name|default('spamassassin') }}
    - enable: {{ datamap.service.enable|default(True) }}

{% for i in datamap.config.manage|default([]) %}
  {% set f = datamap.config[i] %}
sa_config_{{ i }}:
  file:
    - managed
    - name: {{ f.path }}
    - source: {{ f.template_path|default('salt://spamassassin/files/config/' ~ i) }}
    - mode: {{ f.mode|default(644) }}
    - user: {{ f.user|default('root') }}
    - group: {{ f.group|default('root') }}
    - template: jinja
    - watch_in:
      - service: spamassassin
{% endfor %}

pyzor_dir:
  file:
    - directory
    - name: {{ datamap.config.pyzor_dir.path }}
    - user: {{ datamap.user.name }}
    - group: {{ datamap.group.name }}
    - mode: 755

{% set pyzor_cmds = [
  '/usr/bin/pyzor -d --homedir=' ~  datamap.config.pyzor_dir.path ~ ' discover'
  ]
%}

sa_pyzor_init:
  cmd:
    - run
    - name: {{ pyzor_cmds|join(' ') }}
    - user: {{ datamap.user.name }}
    - unless: test -e {{ datamap.config.pyzor_dir.path }}/servers
    - require:
      - file: pyzor_dir
    - require_in:
      - service: spamassassin

razor_dir:
  file:
    - directory
    - name: {{ datamap.config.razor_dir.path }}
    - user: {{ datamap.user.name }}
    - group: {{ datamap.group.name }}
    - mode: 755

{% set razor_cmds = [
  '/usr/bin/razor-admin -d -home=' ~  datamap.config.razor_dir.path ~ ' -register &&',
  '/usr/bin/razor-admin -d -home=' ~  datamap.config.razor_dir.path ~ ' -create &&',
  '/usr/bin/razor-admin -d -home=' ~  datamap.config.razor_dir.path ~ ' -discover'
  ]
%}

sa_razor_init:
  cmd:
    - run
    - name: {{ razor_cmds|join(' ') }}
    - user: {{ datamap.user.name }}
    - unless: test -e {{ datamap.config.razor_dir.path }}/identity
    - require:
      - file: razor_dir
    - require_in:
      - service: spamassassin

{% set f = datamap.config.razor_agent %}
sa_config_razor_agent:
  file:
    - managed
    - name: {{ f.path }}
    - source: {{ f.template_path|default('salt://spamassassin/files/config/razor-agent.conf') }}
    - mode: {{ f.mode|default(644) }}
    - user: {{ f.user|default(datamap.user.name) }}
    - group: {{ f.group|default(datamap.group.name) }}
    - template: jinja
    - require:
      - cmd: sa_razor_init
    - watch_in:
      - service: spamassassin
