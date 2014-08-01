# Example Pillars when using this formula along with https://github.com/bechtoldt/amavis-formula
spamassassin:
  lookup:
    sls_include:
      - amavis
    init_require:
      - pkg: amavis
    config:
      pyzor_dir:
        path: /var/lib/amavis/.pyzor
      razor_dir:
        path: /var/lib/amavis/.razor
      razor_agent:
        path: /var/lib/amavis/razor-agent.conf
        user: amavis
        group: amavis
    razor:
      user:
        name: amavis
      group:
        name: amavis
    pyzor:
      user:
        name: amavis
      group:
        name: amavis
