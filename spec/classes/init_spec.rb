require 'spec_helper'

describe 'auditusers' do

  describe 'when using default values for class' do

    let(:facts) {
      {:fqdn => 'www.google.com'}
    }

    it {

      should contain_file('basedir').with({
        'ensure' => 'directory',
        'path'   => '/opt/auditusers',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
      })

      should contain_file('bindir').with({
        'ensure' => 'directory',
        'path'   => '/opt/auditusers/bin',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
      })

      should contain_file('audit_script').with({
        'path'   => '/opt/auditusers/bin/auditscript.sh',
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'auditgroup',
        'source' => 'puppet:///modules/auditusers/auditscript.sh',
      })

      should_not contain_file('report_vol')

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers/incoming hub',
        'ensure'  => 'present',
        'user'    => 'audituser',
        'minute'  => '48',
      })

      should_not contain_mount('the_mount')

    }

  end

  describe 'when managing user' do
    let(:params) {
      {:manage_user => 'true'}
    }
    it {
      should contain_group('primary_group').with({
        'name'    => 'auditgroup',
        'ensure'  => 'present',
        'gid'     => '8000',
      })

      should contain_user('audit_user').with({
        'name'    => 'audituser',
        'ensure'  => 'present',
        'uid'     => '9000',
        'gid'     => 'auditgroup',
        'groups'  => [],
      })
    }
  end

  describe 'when setting manage_user to an invalid type' do
    let(:params) {
      {:manage_user => ['true']}
    }

    it 'should fail' do
      expect {
        should contain_class('auditusers')
      }.to raise_error(Puppet::Error,/\["true"\] is not a boolean.  It looks to be a Array/)
    end
  end

  describe 'when managing users.allow' do
    let(:params) {
      {:manage_users_allow => 'true'}
    }
    it {
      should contain_exec('add_to_users.allow').with({
        'command' => 'echo audituser@example.com >> /etc/users.allow',
        'onlyif'  => 'test -f /etc/users.allow',
        'unless'  => 'grep -q audituser@example.com /etc/users.allow',
      })
    }
  end

  describe 'when setting manage_users_allow to an invalid type' do
    let(:params) {
      {:manage_users_allow => ['true']}
    }

    it 'should fail' do
      expect {
        should contain_class('auditusers')
      }.to raise_error(Puppet::Error,/\["true"\] is not a boolean.  It looks to be a Array/)
    end
  end

  describe 'when setting custom basedir' do

    let(:facts) {
      {:fqdn => 'www.google.com'}
    }

    let(:params) {
      {:basedir => '/tmp'}
    }

    it {

      should contain_file('basedir').with({
        'ensure' => 'directory',
        'path'   => '/tmp',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
      })

      should contain_file('bindir').with({
        'ensure' => 'directory',
        'path'   => '/tmp/bin',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
      })

      should contain_file('audit_script').with({
        'path'   => '/tmp/bin/auditscript.sh',
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'auditgroup',
      })

      should contain_cron('count_users').with({
        'command' => '/tmp/bin/auditscript.sh /var/run/auditusers/incoming hub',
        'ensure'  => 'present',
        'user'    => 'audituser',
        'minute'  => '48',
      })

    }

  end

  describe 'when setting custom bindir' do

    let(:params) {
      {:bindir => 'foo'}
    }

    it {

      should contain_file('bindir').with({
        'ensure' => 'directory',
        'path'   => '/opt/auditusers/foo',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
      })

    }

  end

  describe 'when setting custom users.allow location' do

    let(:params) {
      {:users_allow        => '/tmp/users.allow',
       :manage_users_allow => 'true'
      }
    }

    it {

      should contain_exec('add_to_users.allow').with({
        'command' => 'echo audituser@example.com >> /tmp/users.allow',
        'onlyif'  => 'test -f /tmp/users.allow',
        'unless'  => 'grep -q audituser@example.com /tmp/users.allow',
      })

    }

  end

  describe 'when setting custom primary group name' do

    let(:params) {
      {:primary_group => 'test_grp',
       :manage_user   => 'true',
      }
    }

    it {

      should contain_group('primary_group').with({
        'name'    => 'test_grp',
        'ensure'  => 'present',
        'gid'     => '8000',
      })

      should contain_user('audit_user').with({
        'name'    => 'audituser',
        'ensure'  => 'present',
        'uid'     => '9000',
        'gid'     => 'test_grp',
      })

      should contain_file('audit_script').with({
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'test_grp',
      })

    }

  end

  describe 'when setting custom primary group id' do

    let(:params) {
      {:gid => '9999',
       :manage_user   => 'true',
      }
    }

    it {

      should contain_group('primary_group').with({
        'name'    => 'auditgroup',
        'ensure'  => 'present',
        'gid'     => '9999',
      })

      should contain_user('audit_user').with({
        'name'    => 'audituser',
        'ensure'  => 'present',
        'uid'     => '9000',
        'gid'     => 'auditgroup',
      })

      should contain_file('audit_script').with({
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'auditgroup',
      })

    }

  end

  describe 'when setting custom groups' do

    let(:params) {
      # FIXME: I would like to test two groups, but I the groups array needs to be
      # unordered. I need to figure out how to do that first.
      #{:groups => {'foo' => { 'gid' => '8888' }, 'bar' => { 'gid' => '8889' }}}
      {:groups => {'foo' => { 'gid' => '8888' }},
       :manage_user   => 'true',
      }
    }

    it {

      should contain_user('audit_user').with({
        'name'    => 'audituser',
        'ensure'  => 'present',
        'uid'     => '9000',
        'gid'     => 'auditgroup',
        'groups'  => ['foo'],
      })

    }

  end

  describe 'when setting custom user' do

    let(:facts) {
      {:fqdn => 'www.google.com'}
    }

    let(:params) {
      {:user => 'testuser',
       :manage_user   => 'true',
      }
    }

    it {

      should contain_user('audit_user').with({
        'name'    => 'testuser',
        'ensure'  => 'present',
        'uid'     => '9000',
        'gid'     => 'auditgroup',
      })

      should contain_file('audit_script').with({
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'auditgroup',
      })

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers/incoming hub',
        'ensure'  => 'present',
        'user'    => 'testuser',
        'minute'  => '48',
      })

    }

  end

  describe 'when setting custom user id' do

    let(:facts) {
      {:fqdn => 'www.google.com'}
    }

    let(:params) {
      {:uid => '9999',
       :manage_user   => 'true',
      }
    }

    it {

      should contain_user('audit_user').with({
        'name'    => 'audituser',
        'ensure'  => 'present',
        'uid'     => '9999',
        'gid'     => 'auditgroup',
      })

      should contain_file('audit_script').with({
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'auditgroup',
      })

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers/incoming hub',
        'ensure'  => 'present',
        'user'    => 'audituser',
        'minute'  => '48',
      })

    }

  end

  describe 'with another fqdn' do

    let(:facts) {
      {:fqdn => 'www2.google.com'}
    }

    it {

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers/incoming hub',
        'ensure'  => 'present',
        'user'    => 'audituser',
        'minute'  => '13',
      })

    }

  end

  describe 'when setting custom cron minute' do

    let(:facts) {
      {:fqdn => 'www.google.com'}
    }

    let(:params) {
      {:cron_minute => '59'}
    }

    it {

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers/incoming hub',
        'ensure'  => 'present',
        'user'    => 'audituser',
        'minute'  => '59',
      })

    }

  end

  describe 'when setting cron ensure to absent' do

    let(:params) {
      {:cron_ensure => 'absent'}
    }

    it {

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers/incoming hub',
        'ensure'  => 'absent',
        'user'    => 'audituser',
      })

    }

  end

  describe 'when using a custom report_vol' do

    let(:facts) {
      {:fqdn => 'www.google.com'}
    }

    let(:params) {
      {:report_vol => '/var/tmp'}
    }

    it {

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/tmp/incoming hub',
        'ensure'  => 'present',
        'user'    => 'audituser',
        'minute'  => '48',
      })

    }

  end

  describe 'when setting mount_report_vol to false' do

    let(:params) {
      {:mount_report_vol => false}
    }

    it {

      should_not contain_mount('the_mount')

    }

  end

  describe 'when setting mount_report_vol to an invalid type' do
    let(:params) {
      {:mount_report_vol => ['true']}
    }

    it 'should fail' do
      expect {
        should contain_class('auditusers')
      }.to raise_error(Puppet::Error,/\["true"\] is not a boolean.  It looks to be a Array/)
    end
  end

  describe 'when setting fstab_entry to a mount hash' do

    let(:params) {
      {:fstab_entry => {'device'   => '/dev/sdb',
                        'fstype'   => 'ext3',
                        'remounts' => true,
                        'atboot'   => true,
                        'options'  => '-',}}
    }

    it {

      should contain_mount('the_mount').with({
        'name'     => '/var/run/auditusers',
        'ensure'   => 'mounted',
        'device'   => '/dev/sdb',
        'fstype'   => 'ext3',
        'remounts' => true,
        'atboot'   => true,
        'options'  => '-',
      })

      should contain_file('report_vol').with({
        'path'   => '/var/run/auditusers',
        'ensure' => 'directory',
      })

    }

  end

  describe 'when setting fstab_entry to a mount hash and mount_report_vol to false' do

    let(:params) {
      { :fstab_entry => {'device'   => '/dev/sdb',
                         'fstype'   => 'ext3',
                         'remounts' => true,
                         'atboot'   => true,
                         'options'  => '-',},
        :mount_report_vol => false,
      }
    }

    it {

      should contain_file('report_vol').with({
        'path'   => '/var/run/auditusers',
        'ensure' => 'absent',
      })

      should contain_mount('the_mount').with({
        'name'     => '/var/run/auditusers',
        'ensure'   => 'absent',
        'device'   => '/dev/sdb',
        'fstype'   => 'ext3',
        'remounts' => true,
        'atboot'   => true,
        'options'  => '-',
      })

    }

  end

  describe 'when setting fstab_entry to an invalid type' do
    let(:params) {
      {:fstab_entry => true}
    }

    it 'should fail' do
      expect {
        should contain_class('auditusers')
      }.to raise_error(Puppet::Error,/fstab entry can either be a hash or undefined/)
    end
  end

  describe 'when setting fstab_entry to an empty string' do
    let(:params) {
      {:fstab_entry => ''}
    }

    it {
      should_not contain_file('report_vol')
    }
  end

  describe 'when using a custom report_dir' do

    let(:facts) {
      {:fqdn => 'www.google.com'}
    }

    let(:params) {
      {:report_dir => 'foo'}
    }

    it {

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers/foo hub',
        'user'    => 'audituser',
        'minute'  => '48',
      })

    }

  end

end
