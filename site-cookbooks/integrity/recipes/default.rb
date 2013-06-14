# Packages first
%w(memcached redis-server htop fail2ban git-core ).each do |required_package|
  package required_package do
    action :install
  end
end

include_recipe 'user'
include_recipe 'application'
include_recipe 'ufw::default'
include_recipe 'unattended-upgrades'
include_recipe 'postgresql::server'
include_recipe 'postgresql::client'
include_recipe 'sqlite'
include_recipe 'runit'

include_recipe 'rvm::system_install'

rubies = ['1.8.7', '1.9.2', '2.0.0-p195', '1.9.3']
rubies.each do |ruby|
  rvm_ruby ruby
end

# Set default ruby to 1.9.3
# TODO update to 2.0 once Chef works on Ruby 2
# Current error looks like: cannot load such file -- rubygems/format
rvm_default_ruby rubies.last

# node.override['firewall']['rules'] = [
#   {"http" => {"port" => 80}},
#   {"https" => {"port" => 443}},
#   {"ssh" => {"port" => 22}}
# ]

firewall "ufw" do
  action :enable
end

firewall_rule "ssh" do
  port 22
  action :allow
  notifies :enable, "firewall[ufw]"
end

firewall_rule "http" do
  port 80
  action :allow
  notifies :enable, "firewall[ufw]"
end

firewall_rule "https" do
  port 443
  action :allow
  notifies :enable, "firewall[ufw]"
end

node.override['postgresql']['version'] = '9.2'

user_account 'integrity' do
  action :create
  create_group true
  ssh_keygen false
end

# Ensure unicorn is installed
rvm_gem "unicorn" do
  ruby_string rubies.last
  action :install
end

# Ensure chef will be present for future chef runs
rvm_gem "chef" do
  ruby_string rubies.last
  action :install
end


application 'integrity' do
  owner 'integrity'
  group 'integrity'
  path '/home/integrity/apps/integrity'
  repository 'git://github.com/3months/integrity.git'
  revision 'master'


  passenger_apache2 do
  end
end


