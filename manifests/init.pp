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
# primary_group
# -------------
# The primary group membership for the auditing user
#
# - *Default*: auditgroup
#
# groups
# ------
# Any other (than the primary) groups the auditing user should belong to
#
# - *Default*: undef
#
# groups_membership
# -----------------
# Whether specified groups should be considered the complete list or the
# minimum list.
#
# - *Default*: minimum
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
# - *Default*: /var/run/auditusers
#
# fstab_entry
# -----------
# The fstab entry as a mount resource hash. If set to undef, no mount/unmount
# will be performed.
#
# - *Default*: undef
#
# mount_report_vol
# ----------------
# Whether the report_vol should be mounted or unmounted. Only used if
# fstab_entry is set to something other than undef.
#
# - *Default*: true
#
# report_dir
# ----------
# The directory in which to report the results relative to $report_vol
#
# - *Default*: incoming
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
  $primary_group = 'auditgroup',
  $groups = undef,
  $groups_membership = 'minimum',
  $gid = '8000',
  $users_allow = '/etc/users.allow',
  $cron_minute = 'auto',
  $report_vol = '/var/run/auditusers',
  $fstab_entry = undef,
  $mount_report_vol = true,
  $report_dir = 'incoming',
  $hub = 'hub',
) {

  if $groups == undef {
    $the_groups = {}
    $the_group_list = []
  } else {
    $the_groups = $groups
    $the_group_defaults = {'ensure' => 'present',}
    $the_group_list = keys($groups)
  }

  if $groups_membership == 'minimum' {
    $the_groups_membership = $groups_membership
  } elsif $groups_membership == 'inclusive' {
    $the_groups_membership = $groups_membership
  } else {
    fail("auditusers::groups_membership can have either of the values 'minimum' or 'inclusive'. groups_membership is currently set to $groups_membership.")
  }

  if $cron_minute == 'auto' {
    $the_minute = fqdn_rand(60)
  } else {
    $the_minute = $cron_minute
  }

  $mount_report_vol_type = type($mount_report_vol)
  if $mount_report_vol_type == 'string' {
    $should_mount_report_vol = str2bool($mount_report_vol)
  } else {
    $should_mount_report_vol = $mount_report_vol
  }

  if $should_mount_report_vol == true {
    $mount_report_vol_ensure = 'mounted'
  } else {
    $mount_report_vol_ensure = 'absent'
  }

  if $fstab_entry != undef {
    if $should_mount_report_vol == true {
      $report_vol_ensure = 'directory'
    } else {
      $report_vol_ensure = 'absent'
    }
    $fstab_entry_type = type($fstab_entry)
    if $fstab_entry_type == 'hash' {
      $my_fstab_entry = {'the_mount' => $fstab_entry, }
      $mount_defaults = {'name'      => $report_vol,
                         'ensure'    => $mount_report_vol_ensure,}
    } else {
      fail("fstab entry can either be a hash or undefined. fstab_entry is defined as $fstab_entry_type.")
    }
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

  exec { 'add_to_users.allow':
    path    => '/usr/xpg4/bin:/bin:/usr/bin:/sbin:/usr/sbin',
    command => "echo ${user}@${domain} >> $users_allow",
    onlyif  => "test -f $users_allow",
    unless  => "grep -q ${user}@${domain} $users_allow",
  }

  group { 'primary_group':
    name    => $primary_group,
    ensure  => present,
    gid     => $gid,
    require => Exec['add_to_users.allow'],
  }

  if $groups != undef {
    create_resources(group, $the_groups)
  }

  user { 'audit_user':
    name       => $user,
    ensure     => present,
    uid        => $uid,
    gid        => $primary_group,
    groups     => $the_group_list,
    membership => $the_groups_membership,
    require    => Group['primary_group'],
  }

  file { 'audit_script':
    path    => "${basedir}/${bindir}/${script_name}",
    ensure  => present,
    mode    => 0750,
    owner   => 'root',
    group   => $primary_group,
    source  => "puppet:///modules/auditusers/${script_name}",
    require => [File['bindir'],
                User['audit_user']],
  }

  if $fstab_entry != undef {

    if $mount_report_vol_ensure == 'mounted' {

      file { 'report_vol':
        path   => $report_vol,
        ensure => 'directory',
        before => Mount['the_mount'],
      }

    } else {

      file { 'report_vol':
        path    => $report_vol,
        ensure  => 'absent',
        force   => true,
        require => Mount['the_mount'],
      }

    }

    create_resources(mount, $my_fstab_entry, $mount_defaults)
  }

  cron { 'count_users':
    command => "${basedir}/${bindir}/${script_name} ${report_vol}/${report_dir} $hub",
    ensure  => $cron_ensure,
    user    => $user,
    minute  => $the_minute,
    require => File['audit_script'],
  }

}
