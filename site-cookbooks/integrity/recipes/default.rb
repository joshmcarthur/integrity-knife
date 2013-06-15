# Packages first
%w( memcached redis-server htop fail2ban git-core ).each do |required_package|
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
include_recipe 'ruby_build'
include_recipe 'rbenv::system'
# include_recipe 'rbenv_passenger::nginx'

rubies = ['1.8.7-p371', '1.9.2-p320', '2.0.0-p195', '1.9.3-p429']
rubies.each do |ruby|
  rbenv_ruby ruby
end

# Set default ruby to 1.9.3
# TODO update to 2.0 once Chef works on Ruby 2
# Current error looks like: cannot load such file -- rubygems/format
rbenv_global rubies.last

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


# Ensure chef will be present for future chef runs
rbenv_gem "chef" do
  rbenv_version rubies.last
  action :install
end

# Ensure bundler is present
rbenv_gem "bundler" do
  rbenv_version rubies.last
  action :install
end

rbenv_gem "passenger" do
  rbenv_version rubies.last
  action :install
end

rbenv_rehash "Rehash installed gems"

# Nginx/Passenger dependencies
%w( nginx-common libcurl4-openssl-dev libssl-dev zlib1g-dev libpcre3-dev ).each do |pkg|
  package pkg do
    action :install
  end
end

# Remove Nginx in case it's installed
%w( nginx ).each do |unrequired_pkg|
  package unrequired_pkg do
    action :purge
  end
end

rbenv_script "Compile Nginx with Passenger support" do
  rbenv_version rubies.last
  user 'root'
  group 'root'
  timeout 5000
  returns [0, 2]
  code %{ passenger-install-nginx-module --auto --auto-download --prefix=/opt/nginx }
  not_if do
    File.directory?("/opt/nginx")
  end
end

# Add our own Nginx config that isn't so loaded with
# commented-out stuff and is ready to serve sites.
template "/opt/nginx/conf/nginx.conf" do
  source "nginx.conf.erb"
  mode 0600
  owner "root"
  group "root"
end

directory "/opt/nginx/sites-available" do
  action :create
end

directory "/opt/nginx/sites-enabled" do
  action :create
end

template "/opt/nginx/sites-available/integrity.conf" do
  source "integrity.conf.erb"
  mode 0600
end

link "/opt/nginx/sites-enabled/integrity.conf" do
  to "/opt/nginx/sites-available/integrity.conf"
end

application 'integrity' do
  owner 'integrity'
  group 'integrity'
  path '/home/integrity/apps/integrity'
  repository 'git://github.com/3months/integrity.git'
  purge_before_symlink ["db"]
  symlinks({"db" => "db"})
  migrate true
  migration_command "bundle exec rake db"
  before_migrate do
    rbenv_script "Bundle install" do
      rbenv_version rubies.last
      cwd release_path
      user 'integrity'
      group 'integrity'
      code %{ bundle install --deployment --without test --path /home/integrity/apps/integrity/shared/bundle }
    end
  end

  revision 'master'
end

# Create shared directories unless they already exist
%w( bundle db ).each do |shared_dir|
  directory "/home/integrity/apps/integrity/shared/#{shared_dir}" do
    owner "integrity"
    group "integrity"
    action :create
  end
end


