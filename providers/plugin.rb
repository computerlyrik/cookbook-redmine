#
# Cookbook Name:: redmine
# Provider:: default
#
# Copyright 2012, Juanje Ojeda <juanje.ojeda@gmail.com>
# Copyright 2013, computerlyrik
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


include Chef::Mixin::LanguageIncludeRecipe


action :create do

  directory "#{new_resource.redmine_dir}/plugins" do
    user     node['apache']['user']
    group    node['apache']['group']
  end

  git "#{new_resource.redmine_dir}/plugins/#{new_resource.name}" do
    repository new_resource.repository
    revision new_resource.revision
    action :sync
  end

  execute "rake redmine:plugins:migrate" do
    environment 'RAILS_ENV' => new_resource.rails_env
    cwd new_resource.redmine_dir
  end

end

