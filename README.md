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

primary\_group
-------------
The group membership for the auditing user

- *Default*: auditgroup

groups
------
Any other (than the primary) groups the auditing user should belong to

- *Default*: undef

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

- *Default*: /var/run/auditusers

fstab\_entry
------------
The fstab entry as a mount resource hash. If undef, no mount/unmount will
be performed.

- *Default*: undef

mount_report_vol
----------------
Whether the report_vol should be mounted or unmounted. Only used if
fstab_entry is set to something other than *undef*

- *Default*: true

report\_dir
-----------

The directory in which to report the results relative to $report_vol

- *Default*: incoming

hub
---
The hub for which to report the results

- *Default*: hub
