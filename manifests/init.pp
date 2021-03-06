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
  $basedir            = '/opt/auditusers',
  $bindir             = 'bin',
  $script_name        = 'auditscript.sh',
  $user               = 'audituser',
  $uid                = '9000',
  $domain             = 'example.com',
  $primary_group      = 'auditgroup',
  $groups             = undef,
  $groups_membership  = 'minimum',
  $gid                = '8000',
  $users_allow        = '/etc/users.allow',
  $cron_minute        = 'auto',
  $cron_ensure        = 'present',
  $report_vol         = '/var/run/auditusers',
  $fstab_entry        = undef,
  $mount_report_vol   = true,
  $report_dir         = 'incoming',
  $hub                = 'hub',
  $manage_user        = false,
  $manage_users_allow = false,
) {

  if is_string($manage_user) {
    $manage_user_real = str2bool($manage_user)
  } else {
    $manage_user_real = $manage_user
  }
  if is_string($manage_users_allow) {
    $manage_users_allow_real = str2bool($manage_users_allow)
  } else {
    $manage_users_allow_real = $manage_users_allow
  }

  validate_bool($manage_user_real)
  validate_bool($manage_users_allow_real)

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

  if ($cron_ensure != 'present') and ($cron_ensure != 'absent') {
    fail("auditusers::cron_ensure can be either 'present' or 'absent'. It is currently set to ${cron_ensure}")
  }

  if is_string($mount_report_vol) {
    $should_mount_report_vol = str2bool($mount_report_vol)
  } else {
    $should_mount_report_vol = $mount_report_vol
  }

  validate_bool($should_mount_report_vol)

  if $should_mount_report_vol == true {
    $mount_report_vol_ensure = 'mounted'
  } else {
    $mount_report_vol_ensure = 'absent'
  }

  if $fstab_entry != '' {
    if $should_mount_report_vol == true {
      $report_vol_ensure = 'directory'
    } else {
      $report_vol_ensure = 'absent'
    }
    if is_hash($fstab_entry) {
      $my_fstab_entry = {'the_mount' => $fstab_entry, }
      $mount_defaults = { 'name'      => $report_vol,
                          'ensure'    => $mount_report_vol_ensure, }
    } else {
      fail('fstab entry can either be a hash or undefined.')
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

  if $manage_users_allow_real == true {
    exec { 'add_to_users.allow':
      path    => '/usr/xpg4/bin:/bin:/usr/bin:/sbin:/usr/sbin',
      command => "echo ${user}@${domain} >> ${users_allow}",
      onlyif  => "test -f ${users_allow}",
      unless  => "grep -q ${user}@${domain} ${users_allow}",
    }
  }

  if $manage_user_real == true {
    group { 'primary_group':
      ensure => present,
      name   => $primary_group,
      gid    => $gid,
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
    $audit_script_require = [ File['bindir'], User['audit_user'], ]
  } else {
    $audit_script_require = File['bindir']
  }

  file { 'audit_script':
    ensure  => present,
    path    => "${basedir}/${bindir}/${script_name}",
    owner   => 'root',
    group   => $primary_group,
    mode    => '0750',
    source  => "puppet:///modules/auditusers/${script_name}",
    require => $audit_script_require
  }

  if $fstab_entry != '' {

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
