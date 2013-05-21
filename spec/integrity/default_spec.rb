require 'rubygems'
require 'bundler/setup'
Bundler.require

describe 'integrity::default' do
  let(:cookbook_paths) { [
    File.expand_path("#{File.dirname(__FILE__)}/../../cookbooks"),
    File.expand_path("#{File.dirname(__FILE__)}/../../site-cookbooks")
  ] }

  let(:chef_run) do
    ChefSpec::ChefRunner.new({cookbook_path: cookbook_paths}) do |node|
      node.override['cpu']['total'] = 2
    end.converge("integrity::default")
  end

  required_packages = %w( git-core htop memcached redis-server fail2ban)
  required_packages.each { |pkg| it { expect(chef_run).to install_package(pkg) } }

  included_recipes = %w( user unattended-upgrades postgresql::server application ufw::default sqlite)
  included_recipes.each { |recipe| it { expect(chef_run).to include_recipe(recipe) } }

  it { chef_run.node['postgresql']['version'].should eq '9.2' }
  it { chef_run.node['rvm']['default_ruby'].should eq '2.0.0-p195' }
  it { chef_run.node['rvm']['group_users'].should eq ['integrity'] }

  %w( http https ssh ).each do |service|
    it { firewall_rules.key?(service).should be_true }
  end
end

def firewall_rules
  rules ||= {}
  chef_run.node['firewall']['rules'].each { |r| rules = rules.merge(r) }
  rules
end