#!/bin/bash

# install the relevant packages
sudo dnf update
sudo dnf install krb5-server krb5-libs krb5-workstation

# Configure the kerberos config file:
cat EOF-<< | tee a /etc/krb5.conf
[realms]
IGWEGBU.TECH = {
     kdc = aap.igwegbu.tech
     admin_server = aap.igwegbu.tech
}

[domain_realm]
 .igwegbu.tech = IGWEGBU.TECH
  igwegbu.tech = IGWEGBU.TECH
EOF

# Within the [libdefaults] section, ensure:
#     default_realm = IGWEGBU.TECH

# initialise the krb5 database and stash the master key:
sudo kdb5_util create -s -P redhat
# sudo kdb5_util create -s  # prompts for password

# Start and enable the kerberos server and admin daemons:
sudo systemctl enable --now krb5-kdc
sudo systemctl enable --now kadmin

# To backup the database, first stop the kdc and kadmin services
sudo systemctl stop krb5kdc
sudo systemctl stop kadmin
sudo mkdir -p /var/backups
sudo kdb5_util dump /var/backups/kerberos.dump

# You can automate that with a cronjob:
sudo crontab -e
0 2 * * * /usr/sbin/kdb5_util dump /var/backups/kerberos_$(date +\%Y\%m\%d).dump
# Consider encrypting and storing the dump file offsite

[aap@aap ~]$ sudo kadmin.local
Authenticating as principal root/admin@IGWEGBU.TECH with password.
kadmin.local:  addprinc -pw aap +needchange aap
No policy specified for aap@IGWEGBU.TECH; defaulting to no policy
Principal "aap@IGWEGBU.TECH" created.
kadmin.local:  getprinc aap
Principal: aap@IGWEGBU.TECH
Expiration date: [never]
Last password change: Tue Aug 06 16:02:26 CDT 2024
Password expiration date: [never]
Maximum ticket life: 1 day 00:00:00
Maximum renewable life: 0 days 00:00:00
Last modified: Tue Aug 06 16:02:27 CDT 2024 (root/admin@IGWEGBU.TECH)
Last successful authentication: [never]
Last failed authentication: [never]
Failed password attempts: 0
Number of keys: 7
Key: vno 1, aes256-cts-hmac-sha384-192
Key: vno 1, aes128-cts-hmac-sha256-128
Key: vno 1, aes256-cts-hmac-sha1-96
Key: vno 1, aes128-cts-hmac-sha1-96
Key: vno 1, camellia256-cts-cmac
Key: vno 1, camellia128-cts-cmac
Key: vno 1, DEPRECATED:arcfour-hmac
MKey: vno 1
Attributes: REQUIRES_PWCHANGE
Policy: [none]
kadmin.local:
