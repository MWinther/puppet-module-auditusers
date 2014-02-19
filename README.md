# auditusers module #

[![Build Status](
https://api.travis-ci.org/MWinther/puppet-module-auditusers.png?branch=master)](https://travis-ci.org/MWinther/puppet-module-auditusers)

This module handles the user auditing using the biit360 system.

It optionally mounts a filesystem where the reporting should take place, and
makes sure that the correct user, groups, script and cron job are available
on the system. The actual reporting is done by the script that is run by the
cron job.

# Compatibility #

This module has been tested to work on the following systems:

 * RHEL 6
 * Solaris 10

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

cron\_ensure
-----------
Which status the cron job should be ensured to have.

- *Default*: present

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

manage_user
-----------
Manage user and group needed for script and cronjob

- *Default*: false
