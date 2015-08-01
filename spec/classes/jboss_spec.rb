require 'spec_helper'

describe 'jboss' do

  let(:title) { 'jboss' }
  let(:node) { 'rspec.example42.com' }
  let(:facts) { {
      :ipaddress => '10.42.42.42',
      :operatingsystem => 'RedHat',
      :concat_basedir => '/dne'
  } }

  describe 'Test standard installation via package' do
    let(:params) { {:install => 'package' } }

    it { should contain_package('jboss').with_ensure('present') }
  end

  describe 'Test installation via netinstall' do
    let(:params) { {:version => '6' } }
    it 'should install version 6 via netinstall' do
      should contain_puppi__netinstall('netinstall_jboss').with_url("http://download.jboss.org/jbossas/6.1/jboss-as-distribution-6.1.0.Final.zip")
    end
  end

  describe 'Test installation via puppi' do
    let(:params) { {:version => '6' , :install => 'puppi' } }
    it 'should install version 6 via puppi' do
      should contain_puppi__project__archive('jboss').with_source("http://download.jboss.org/jbossas/6.1/jboss-as-distribution-6.1.0.Final.zip")
    end
  end

  describe 'Test package installation with monitoring and firewalling' do
    let(:params) { {:monitor => true , :install => 'package' , :firewall => true, :port => '42', :protocol => 'tcp' } }

    it { should contain_package('jboss').with_ensure('present') }
    it 'should monitor the process' do
      should contain_monitor__process('jboss_process').with_enable(true)
    end
    it 'should place a firewall rule' do
      should contain_firewall('jboss_tcp_42').with_enable(true)
    end
  end

  describe 'Test decommissioning - absent' do
    let(:params) { {:absent => true, :install => 'package', :monitor => true , :firewall => true, :port => '42', :protocol => 'tcp'} }

    it 'should remove Package[jboss]' do should contain_package('jboss').with_ensure('absent') end 
    it 'should not enable at boot Service[jboss]' do should contain_service('jboss').with_enable('false') end
    it 'should not monitor the process' do
      should contain_monitor__process('jboss_process').with_enable(false)
    end
    it 'should remove a firewall rule' do
      should contain_firewall('jboss_tcp_42').with_enable(false)
    end
  end

  describe 'Test decommissioning - disable' do
    let(:params) { {:disable => true, :install => 'package', :monitor => true , :firewall => true, :port => '42', :protocol => 'tcp'} }

    it { should contain_package('jboss').with_ensure('present') }
    it 'should not monitor the process' do
      should contain_monitor__process('jboss_process').with_enable(false)
    end
    it 'should remove a firewall rule' do
      should contain_firewall('jboss_tcp_42').with_enable(false)
    end
  end

  describe 'Test decommissioning - disableboot' do
    let(:params) { {:disableboot => true, :install => 'package', :monitor => true , :firewall => true, :port => '42', :protocol => 'tcp'} }
  
    it { should contain_package('jboss').with_ensure('present') }
    it 'should not enable at boot Service[jboss]' do should contain_service('jboss').with_enable('false') end
    it 'should not monitor the process locally' do
      should contain_monitor__process('jboss_process').with_enable(false)
    end
    it 'should keep a firewall rule' do
      should contain_firewall('jboss_tcp_42').with_enable(true)
    end
  end 

  describe 'Test customizations - template' do
    let(:params) { {:template => "jboss/spec.erb" , :options => { 'opt_a' => 'value_a' } } }

    it 'should generate a valid template' do
      should contain_file('jboss.conf').with_content(/fqdn: rspec.example42.com/)
    end
    it 'should generate a template that uses custom options' do
      should contain_file('jboss.conf').with_content(/value_a/)
    end

  end

  describe 'Test customizations - source' do
    let(:params) { {:source => "puppet://modules/jboss/spec" , :source_dir => "puppet://modules/jboss/dir/spec" , :source_dir_purge => true } }

    it 'should request a valid source ' do
      should contain_file('jboss.conf').with_source("puppet://modules/jboss/spec")
    end
    it 'should request a valid source dir' do
      should contain_file('jboss.dir').with_source("puppet://modules/jboss/dir/spec")
    end
    it 'should purge source dir if source_dir_purge is true' do
      should contain_file('jboss.dir').with_purge(true)
    end
  end

  describe 'Test customizations - custom class' do
    let(:params) { {:my_class => "jboss::spec" , :template => "jboss/spec.erb"} }
    it 'should automatically include a custom class' do
      should contain_file('jboss.conf').with_content(/fqdn: rspec.example42.com/)
    end
  end

  describe 'Test Puppi Integration' do
    let(:params) { {:puppi => true, :puppi_helper => "myhelper"} }

    it 'should generate a puppi::ze define' do
      should contain_puppi__ze('jboss').with_helper("myhelper")
    end
  end

  describe 'Test Monitoring Tools Integration' do
    let(:params) { {:monitor => true, :monitor_tool => "puppi" } }

    it 'should generate monitor defines' do
      should contain_monitor__process('jboss_process').with_tool("puppi")
    end
  end

  describe 'Test Firewall Tools Integration' do
    let(:params) { {:firewall => true, :firewall_tool => "iptables" , :protocol => "tcp" , :port => "42" } }

    it 'should generate correct firewall define' do
      should contain_firewall('jboss_tcp_42').with_tool("iptables")
    end
  end

  describe 'Test OldGen Module Set Integration' do
    let(:params) { {:monitor => "yes" , :monitor_tool => "puppi" , :firewall => "yes" , :firewall_tool => "iptables" , :puppi => "yes" , :port => "42" , :protocol => 'tcp' } }

    it 'should generate monitor resources' do
      should contain_monitor__process('jboss_process').with_tool("puppi")
    end
    it 'should generate firewall resources' do
      should contain_firewall('jboss_tcp_42').with_tool("iptables")
    end
    it 'should generate puppi resources ' do 
      should contain_puppi__ze('jboss').with_ensure("present")
    end
  end

  describe 'Test params lookup' do
    let(:facts) { { :monitor => true , :ipaddress => '10.42.42.42' , :operatingsystem => 'RedHat' } }
    let(:params) { { :port => '42' } }

    it 'should honour top scope global vars' do
      should contain_monitor__process('jboss_process').with_enable(true)
    end
  end

  describe 'Test params lookup' do
    let(:facts) { { :jboss_monitor => true , :ipaddress => '10.42.42.42' , :operatingsystem => 'RedHat' } }
    let(:params) { { :port => '42' } }

    it 'should honour module specific vars' do
      should contain_monitor__process('jboss_process').with_enable(true)
    end
  end

  describe 'Test params lookup' do
    let(:facts) { { :monitor => false , :jboss_monitor => true , :ipaddress => '10.42.42.42' , :operatingsystem => 'RedHat' } }
    let(:params) { { :port => '42' } }

    it 'should honour top scope module specific over global vars' do
      should contain_monitor__process('jboss_process').with_enable(true)
    end
  end

  describe 'Test params lookup' do
    let(:facts) { { :monitor => false , :ipaddress => '10.42.42.42' , :operatingsystem => 'RedHat' } }
    let(:params) { { :monitor => true , :firewall => true, :port => '42' } }

    it 'should honour passed params over global vars' do
      should contain_monitor__process('jboss_process').with_enable(true)
    end
  end

end

