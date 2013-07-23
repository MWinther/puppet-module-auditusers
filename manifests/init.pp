# == Class: module-auditusers
#
# This module handles user auditing.
#
# It optionally mounts a filesystem where the reporting should take place, and
# makes sure that the correct user, groups, script and cron job are available
# on the system. The actual reporting is done by the auditing script, which
# writes a file to the report directory.
#
class auditusers (
  $basedir           = '/opt/auditusers',
  $bindir            = 'bin',
  $script_name       = 'auditscript.sh',
  $user              = 'audituser',
  $uid               = '9000',
  $domain            = 'example.com',
  $primary_group     = 'auditgroup',
  $groups            = undef,
  $groups_membership = 'minimum',
  $gid               = '8000',
  $users_allow       = '/etc/users.allow',
  $cron_minute       = 'auto',
  $report_vol        = '/var/run/auditusers',
  $fstab_entry       = undef,
  $mount_report_vol  = true,
  $report_dir        = 'incoming',
  $hub               = 'hub',
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
    fail("auditusers::groups_membership can have either of the values 'minimum' or 'inclusive'. groups_membership is currently set to ${groups_membership}.")
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
      $mount_defaults = { 'name'      => $report_vol,
                          'ensure'    => $mount_report_vol_ensure, }
    } else {
      fail("fstab entry can either be a hash or undefined. fstab_entry is defined as ${fstab_entry_type}.")
    }
  }

  file { 'basedir':
    ensure => directory,
    name   => $basedir,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { 'bindir':
    ensure => directory,
    name   => "${basedir}/${bindir}",
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  exec { 'add_to_users.allow':
    path    => '/usr/xpg4/bin:/bin:/usr/bin:/sbin:/usr/sbin',
    command => "echo ${user}@${domain} >> ${users_allow}",
    onlyif  => "test -f ${users_allow}",
    unless  => "grep -q ${user}@${domain} ${users_allow}",
  }

  group { 'primary_group':
    ensure  => present,
    name    => $primary_group,
    gid     => $gid,
    require => Exec['add_to_users.allow'],
  }

  if $groups != undef {
    create_resources(group, $the_groups)
  }

  user { 'audit_user':
    ensure     => present,
    name       => $user,
    uid        => $uid,
    gid        => $primary_group,
    groups     => $the_group_list,
    membership => $the_groups_membership,
    require    => Group['primary_group'],
  }

  file { 'audit_script':
    ensure  => present,
    path    => "${basedir}/${bindir}/${script_name}",
    owner   => 'root',
    group   => $primary_group,
    mode    => '0750',
    source  => "puppet:///modules/auditusers/${script_name}",
    require => [ File['bindir'],
                User['audit_user'],
                ],
  }

  if $fstab_entry != undef {

    if $mount_report_vol_ensure == 'mounted' {

      file { 'report_vol':
        ensure => 'directory',
        path   => $report_vol,
        before => Mount['the_mount'],
      }

    } else {

      file { 'report_vol':
        ensure  => 'absent',
        path    => $report_vol,
        force   => true,
        require => Mount['the_mount'],
      }
    }

    create_resources(mount, $my_fstab_entry, $mount_defaults)
  }

  cron { 'count_users':
    ensure  => $cron_ensure,
    command => "${basedir}/${bindir}/${script_name} ${report_vol}/${report_dir} ${hub}",
    user    => $user,
    minute  => $the_minute,
    require => File['audit_script'],
  }
}
