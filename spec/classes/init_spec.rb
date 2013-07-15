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

      should contain_file('etcdir').with({
        'ensure' => 'directory',
        'path'   => '/etc/auditusers',
        'owner'  => 'root',
        'group'  => 'auditgroup',
        'mode'   => '0755',
      })

      should contain_exec('add_to_users.allow').with({
        'command' => 'echo audituser@example.com >> /etc/users.allow',
        'onlyif'  => 'test -f /etc/users.allow',
        'unless'  => 'grep -q audituser@example.com /etc/users.allow',
      })

      should contain_group('audit_group').with({
        'name'    => 'auditgroup',
        'ensure'  => 'present',
        'gid'     => '8000',
      })

      should contain_user('audit_user').with({
        'name'    => 'audituser',
        'ensure'  => 'present',
        'uid'     => '9000',
        'groups'  => 'auditgroup',
      })

      should contain_file('audit_script').with({
        'path'   => '/opt/auditusers/bin/auditscript.sh',
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'auditgroup',
        'source' => 'puppet:///modules/auditusers/auditscript.sh',
      })

      should contain_file('fact_config').with({
        'path' => '/etc/auditusers/fact_config',
        'ensure' => 'present',
        'mode' => '0644',
        'owner' => 'root',
        'group' => 'auditgroup',
      })

      should contain_file('fact_config').with_content(
%{# This file is being maintained by Puppet.
# DO NOT EDIT
report_vol = /var/run
})

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers hub',
        'user'    => 'audituser',
        'minute'  => '48',
      })

    }

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

      should contain_file('etcdir').with({
        'ensure' => 'directory',
        'path'   => '/etc/auditusers',
        'owner'  => 'root',
        'group'  => 'auditgroup',
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
        'command' => '/tmp/bin/auditscript.sh /var/run/auditusers hub',
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
      {:users_allow => '/tmp/users.allow'}
    }

    it {

      should contain_exec('add_to_users.allow').with({
        'command' => 'echo audituser@example.com >> /tmp/users.allow',
        'onlyif'  => 'test -f /tmp/users.allow',
        'unless'  => 'grep -q audituser@example.com /tmp/users.allow',
      })

    }

  end

  describe 'when setting custom group name' do

    let(:params) {
      {:group => 'test_grp'}
    }

    it {

      should contain_group('audit_group').with({
        'name'    => 'test_grp',
        'ensure'  => 'present',
        'gid'     => '8000',
      })

      should contain_user('audit_user').with({
        'name'    => 'audituser',
        'ensure'  => 'present',
        'uid'     => '9000',
        'groups'  => 'test_grp',
      })

      should contain_file('audit_script').with({
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'test_grp',
      })

    }

  end

  describe 'when setting custom group id' do

    let(:params) {
      {:gid => '9999'}
    }

    it {

      should contain_group('audit_group').with({
        'name'    => 'auditgroup',
        'ensure'  => 'present',
        'gid'     => '9999',
      })

      should contain_user('audit_user').with({
        'name'    => 'audituser',
        'ensure'  => 'present',
        'uid'     => '9000',
        'groups'  => 'auditgroup',
      })

      should contain_file('audit_script').with({
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'auditgroup',
      })

    }

  end

  describe 'when setting custom user' do

    let(:facts) {
      {:fqdn => 'www.google.com'}
    }

    let(:params) {
      {:user => 'testuser'}
    }

    it {

      should contain_user('audit_user').with({
        'name'    => 'testuser',
        'ensure'  => 'present',
        'uid'     => '9000',
        'groups'  => 'auditgroup',
      })

      should contain_file('audit_script').with({
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'auditgroup',
      })

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers hub',
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
      {:uid => '9999'}
    }

    it {

      should contain_user('audit_user').with({
        'name'    => 'audituser',
        'ensure'  => 'present',
        'uid'     => '9999',
        'groups'  => 'auditgroup',
      })

      should contain_file('audit_script').with({
        'ensure' => 'present',
        'mode'   => '0750',
        'owner'  => 'root',
        'group'  => 'auditgroup',
      })

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers hub',
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
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers hub',
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
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/auditusers hub',
        'user'    => 'audituser',
        'minute'  => '59',
      })

    }

  end

  describe 'when using a custom report_vol' do

    let(:params) {
      {:report_vol => '/var/tmp'}
    }

    it {

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/tmp/auditusers hub',
        'user'    => 'audituser',
        'minute'  => '45',
      })

    }

  end

  describe 'when using a custom report_dir' do

    let(:params) {
      {:report_dir => 'foo'}
    }

    it {

      should contain_cron('count_users').with({
        'command' => '/opt/auditusers/bin/auditscript.sh /var/run/foo hub',
        'user'    => 'audituser',
        'minute'  => '45',
      })

    }

  end

end
