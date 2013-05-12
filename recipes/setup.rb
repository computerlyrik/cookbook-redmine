#
# Cookbook Name:: redmine
# Recipe:: default
#
# Copyright 2012, Juanje Ojeda <juanje.ojeda@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

# set through recipes the base system
case node['platform']
when "redhat","centos","amazon","scientific","fedora","suse"
  include_recipe "yum::epel"
when "debian","ubuntu"
  include_recipe "apt"
end

#TODO autogenerate password
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

include_recipe "apache2"
include_recipe "apache2::mod_rewrite"
include_recipe "passenger_apache2::mod_rails"
include_recipe "mysql::server"
include_recipe "git"

# this is because is the only site. Otherwise it should be removed
apache_site "000-default" do
  enable false
end

#Install Bundler
if platform?("debian","ubuntu")
  if node['platform_version'].to_f < 10.10
    %w{libopenssl-ruby rake}.each do |package_name|
      package package_name do
        action :install
      end
    end
    gem_package "rubygems-update" do
      action :install
    end
    execute "update rubygems" do
      command '/var/lib/gems/1.8/bin/update_rubygems'
    end
    execute "install bundler" do
      command 'gem install bundler'
    end
  else
    gem_package "bundler" do
      action :install
    end
  end
else
  gem_package "bundler" do
    action :install
  end
end

# install the dependencies
packages = node['redmine']['packages'].values.flatten
packages.each do |pkg|
  package pkg
end

node['redmine']['gems'].each_pair do |gem,ver|
  gem_package gem do
    action :install
    version ver if ver && ver.length > 0
  end
end
