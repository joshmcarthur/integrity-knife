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
      node.override['rbenv']['install_pkgs'] = []
    end.converge("integrity::default")
  end

  required_packages = %w( git-core htop memcached redis-server fail2ban git-core)
  required_packages.each { |pkg| it { expect(chef_run).to install_package(pkg) } }

  included_recipes = %w( rbenv::system_install ruby_build user unattended-upgrades postgresql::server application ufw::default sqlite)
  included_recipes.each { |recipe| it { expect(chef_run).to include_recipe(recipe) } }

  it { chef_run.node['postgresql']['version'].should eq '9.2' }

  %w( http https ssh ).each do |service|
    it { firewall_rules.key?(service).should be_true }
  end
end

def firewall_rules
  rules ||= {}
  chef_run.node['firewall']['rules'].each { |r| rules = rules.merge(r) }
  rules
end