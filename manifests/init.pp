# == Class: module-auditusers
#
# Full description of class module-auditusers here.
#
# === Parameters
#
# basedir
# -------
# The basedir for the installation
#
# - *Default*: /opt/auditusers
#
# bindir
# -------
# The directory in which to place the script relative to $basedir
#
# - *Default*: bin
#
# script_name
# -----------
# The script to use for the auditing
#
# - *Default*: auditscript.sh
#
# user
# ----
# The name of the auditing user
#
# - *Default*: audituser
#
# uid
# ---
# The uid for the auditing user
#
# - *Default*: 9000
#
# domain
# ------
# The domain the user should use in the users.allow file
#
# - *Default*: example.com
#
# group
# -----
# The group membership for the auditing user
#
# - *Default*: auditgroup
#
# gid
# ---
# The group ID for the auditing group
#
# - *Default*: 8000
#
# users_allow
# -----------
# The full path to the users.allow file
#
# - *Default*: /etc/users.allow
#
# cron_minute
# -----------
# The minute on the hour on which the script should run
#
# - *Default*: auto (randomized based on host)
#
# report_vol
# ----------
# The volume on which to report the results
#
# - *Default*: /var/run
#
# report_dir
# ----------
# The directory in which to report the results relative to $report_vol
#
# - *Default*: auditusers
#
# hub
# ---
# The hub for which to report the results
#
# - *Default*: hub
#

class auditusers (
  $basedir = '/opt/auditusers',
  $bindir = 'bin',
  $script_name = 'auditscript.sh',
  $user = 'audituser',
  $uid = '9000',
  $domain = 'example.com',
  $group = 'auditgroup',
  $gid = '8000',
  $users_allow = '/etc/users.allow',
  $cron_minute = 'auto',
  $report_vol = '/var/run',
  $report_dir = 'auditusers',
  $hub = 'hub',
) {

  $etcdir = '/etc/auditusers'

  if $cron_minute == 'auto' {
    $the_minute = fqdn_rand(60)
  } else {
    $the_minute = $cron_minute
  }

  if $::auditusers_report_vol_mounted == 'true' {
    $cron_ensure = 'present'
  } else {
    $cron_ensure = 'absent'
  }

  file { 'basedir':
    name   => $basedir,
    ensure => directory,
    mode   => 0755,
    owner  => 'root',
    group  => 'root',
  }

  file { 'bindir':
    name   => "${basedir}/${bindir}",
    ensure => directory,
    mode   => 0755,
    owner  => 'root',
    group  => 'root',
  }

  file { 'etcdir':
    name   => "${etcdir}",
    ensure => directory,
    mode   => 0755,
    owner  => 'root',
    group  => "$group",
  }

  exec { 'add_to_users.allow':
    path    => '/usr/xpg4/bin:/bin:/usr/bin:/sbin:/usr/sbin',
    command => "echo ${user}@${domain} >> $users_allow",
    onlyif  => "test -f $users_allow",
    unless  => "grep -q ${user}@${domain} $users_allow",
  }

  group { 'audit_group':
    name    => $group,
    ensure  => present,
    gid     => $gid,
    require => Exec['add_to_users.allow'],
  }

  user { 'audit_user':
    name    => $user,
    ensure  => present,
    uid     => $uid,
    groups  => $group,
    require => Group['audit_group']
  }

  file { 'audit_script':
    path    => "${basedir}/${bindir}/${script_name}",
    ensure  => present,
    mode    => 0750,
    owner   => 'root',
    group   => $group,
    source  => "puppet:///modules/auditusers/${script_name}",
    require => [File['bindir'],
                User['audit_user']],
  }

  file { 'fact_config':
    path    => "${etcdir}/fact_config",
    ensure  => present,
    mode    => 0644,
    owner   => 'root',
    group   => "$group",
    content => template('auditusers/fact_config.erb'),
  }

  cron { 'count_users':
    command => "${basedir}/${bindir}/${script_name} ${report_vol}/${report_dir} $hub",
    ensure  => $cron_ensure,
    user    => $user,
    minute  => $the_minute,
    require => File['audit_script'],
  }

}
