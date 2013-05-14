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

  # Some handy vars
  environment = @new_resource.env
  adapter = @new_resource.db_adapter

  database = {'adapter' => @new_resource.db_adapter, 'database' => @new_resource.db_database, 'username' => @new_resource.db_username, 'password' => @new_resource.db_password}

  case adapter
  when "mysql"
    include_recipe "mysql::server"
    include_recipe "database::mysql"
  when "postgresql"
    include_recipe "postgresql::server"
    include_recipe "database::postgresql"
  end


  case adapter
  when "mysql"
    connection_info = {
      :host => "localhost",
      :username => 'root',
      :password => node['mysql']['server_root_password'].empty? ? '' : node['mysql']['server_root_password']
    }
  when "postgresql"
    connection_info = {
      :host => "localhost",
      :username => 'postgres',
      :password => node['postgresql']['password']['postgres'].empty? ? '' : node['postgresql']['password']['postgres']
    }
  end

  database @new_resource.db_database do
    connection connection_info
    case adapter
    when "mysql"
      provider Chef::Provider::Database::Mysql
    when "postgresql"
      provider Chef::Provider::Database::Postgresql
    end
    action :create
  end

  database_user @new_resource.db_username do
    connection connection_info
    database_name new_resource.db_database
    password new_resource.db_password
    case adapter
    when "mysql"
      provider Chef::Provider::Database::MysqlUser
    when "postgresql"
      provider Chef::Provider::Database::PostgresqlUser
    end
    privileges [:all]
    action [:create, :grant]
  end


  webpath = "/var/www/#{new_resource.name}"
  server_name = "#{new_resource.name}.#{node['domain']}"
  server_aliases = [@new_resource.name]

  # set up the Apache site
  web_app @new_resource.name do
    docroot        ::File.join(webpath, 'public')
    template       "redmine.conf.erb"
    cookbook       "redmine"
    server_name    server_name
    server_aliases server_aliases
    rails_env      environment
  end

  deploy_to = "#{new_resource.basedir}/#{new_resource.name}"
  repo = @new_resource.repository
  version = @new_resource.version

  # deploy the Redmine app
  include_recipe "git"
  deploy_revision deploy_to do
    repo     repo
    revision "#{version}-stable"
    user     node['apache']['user']
    group    node['apache']['group']
    environment "RAILS_ENV" => environment
    shallow_clone false

    before_migrate do
      %w{config log system pids}.each do |dir|
        directory "#{deploy_to}/shared/#{dir}" do
          owner node['apache']['user']
          group node['apache']['group']
          mode '0755'
          recursive true
        end
      end

      template "#{deploy_to}/shared/config/database.yml" do
        cookbook "redmine"
        source "database.yml.erb"
#        owner node['redmine']['user']
#        group node['redmine']['group']
        mode "644"
        variables(
          :host => 'localhost',
          :db => database,
          :rails_env => environment
        )
      end

      case adapter
      when "mysql"
        execute "bundle install --without development test mysql sqlite" do
          cwd release_path
        end
      when "postgresql"
        execute "bundle install --without development test postgresql sqlite" do
          cwd release_path
        end
      end
      

      if Gem::Version.new(version) < Gem::Version.new('2.0.0')
        execute 'rake generate_session_store' do
          cwd release_path
          not_if { ::File.exists?("#{release_path}/db/schema.rb") }
        end
      else
        execute 'rake generate_secret_token' do
          cwd release_path
          not_if { ::File.exists?("#{release_path}/config/initializers/secret_token.rb") }
        end
      end
    end

    migrate true
    migration_command 'rake db:migrate'

    create_dirs_before_symlink %w{tmp public config tmp/pdf public/plugin_assets}

    before_restart do
      link webpath do
        to release_path
      end
    end
    action :deploy
    notifies :restart, "service[apache2]"
  end
end

