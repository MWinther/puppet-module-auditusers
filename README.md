# auditusers module #

This module handles the user auditing using the biit360 system.

# Compatibility #

This module is currently totally untested.

# Parameters #

basedir
-------
The basedir for the installation

- *Default*: /opt/auditusers

bindir
-------
The directory in which to place the script relative to $basedir

- *Default*: bin

script\_name
-----------
The script to use for the auditing

- *Default*: auditscript.sh

user
----
The name of the auditing user

- *Default*: audituser

uid
---
The uid for the auditing user

- *Default*: 9000

domain
------
The domain the user should use in the users.allow file

- *Default*: example.com

group
-----
The group membership for the auditing user

- *Default*: auditgroup

gid
---
The group ID for the auditing group

- *Default*: 8000

users\_allow
-----------
The full path to the users.allow file

- *Default*: /etc/users.allow

cron\_minute
-----------
The minute on the hour on which the script should run

- *Default*: auto (randomized based on host)

report\_vol
-----------
The volume on which to report the results

- *Default*: /var/run

report\_dir
-----------

The directory in which to report the results relative to $report_vol

- *Default*: auditusers

hub
---
The hub for which to report the results

- *Default*: hub
