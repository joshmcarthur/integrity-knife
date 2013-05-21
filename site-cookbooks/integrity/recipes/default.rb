# Packages first
%w(memcached redis-server htop fail2ban).each do |required_package|
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
include_recipe 'postgresql::libpq'
include_recipe 'sqlite'

# Uncomment if testing with vagrant
include_recipe 'rvm::vagrant'

# include_recipe 'rvm::system'

node.override['rvm']['rubies'] = [
  '1.8.7',
  '1.9.2',
  '1.9.3',
  '2.0.0-p195'
]


node.override['rvm']['default_ruby'] = '2.0.0-p195'
node.override['rvm']['group_users'] = ['integrity']

node.override['firewall']['rules'] = [
  {"http" => {"port" => 80}},
  {"https" => {"port" => 443}},
  {"ssh" => {"port" => 22}}
]

node.override['postgresql']['version'] = '9.2'


user_account 'integrity' do
  action :create
  create_group true
  ssh_keygen false
end

application 'integrity' do
  owner 'integrity'
  group 'integrity'
  path '/home/integrity/apps/integrity'
  repository 'git://github.com/3months/integrity.git'


  unicorn do
    bundler true
    worker_processes 2
  end
end


