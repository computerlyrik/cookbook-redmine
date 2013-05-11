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




action :create do

  # set up the databas
  database = { :adapter => @new_resource.db_adapter, :database => @new_resource.db_database, :username => @new_resource.db_username, :password => @new_resource.db_password }
  databases = {:env => @new_resource.env, :db => database}
  redmine_sql = "/tmp/redmine_#{@new_resource.name}.sql"
  Chef::Log.error(databases)
  template redmine_sql do
    source 'redmine.sql.erb'
    variables(
      :host => 'localhost',
      :databases => databases
    )
  end

  execute "create #{@new_resource.name} database" do
    command "#{node['mysql']['mysql_bin']} -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < #{redmine_sql}"
    action :nothing
    subscribes :run, resources("template[#{redmine_sql}]"), :immediately
    not_if { ::File.exists?("/var/lib/mysql/#{@new_resource.db_database}") }
  end

  webpath = "/var/www/#{new_resource.name}"
  # set up the Apache site
  web_app "redmine" do
    docroot        ::File.join(webpath, 'public')
    template       "redmine.conf.erb"
    server_name    "#{new_resource.name}.#{node['domain']}"
    server_aliases [ @new_resource.name, node['hostname'] ]
    rails_env      @new_resource.env
  end

  deploy_to = "#{new_resource.basedir}/#{new_resource.name}"
  # deploy the Redmine app
  deploy_revision deploy_to do
    repo     @new_resource.repo
    revision "#{new_resource.version}-STABLE"
    user     node['apache']['user']
    group    node['apache']['group']
    environment "RAILS_ENV" => @new_resource.env
    shallow_clone true

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
        source "database.yml.erb"
#        owner node['redmine']['user']
#        group node['redmine']['group']
        mode "644"
        variables(
          :host => 'localhost',
          :databases => databases,
          :rails_env => @new_resource.env
        )
      end

      execute 'bundle install --without development test' do
        cwd release_path
      end
      
      # generate_secret_token for 2.x , session_store for 1.x
      cmd = node['redmine']['version'] < 2 ? "generate_session_store" : "generate_secret_token"
      execute cmd do
        cwd release_path
        not_if { ::File.exists?("#{release_path}/db/schema.rb") }
      end
    end

    migrate true
    migration_command 'rake db:migrate'

    before_restart do
      link webpath do
        to release_path
      end
    end
    action :deploy
    notifies :restart, "service[apache2]"
  end
end

