#
# Cookbook Name:: liquid-feedback
# Resource:: default
#
# Copyright 2012, computerlyrik
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

actions :create #TODO, :start, :disable

default_action :create

attribute :name, :kind_of => String, :name_attribute => true

attribute :repository, :kind_of => String, :default =>  "git://github.com/redmine/redmine.git"
attribute :version, :kind_of => String, :required => true

attribute :language, :kind_of => String, :default =>  "de"
attribute :env, :kind_of => String, :default =>  "production"

attribute :basedir, :kind_of => String, :default =>  "/opt/redmine"
#attribute :alias, :kind_of => String

attribute :db_adapter, :kind_of => String, :default => "mysql"
attribute :db_database, :kind_of => String, :required => true
attribute :db_username, :kind_of => String, :required => true
attribute :db_password, :kind_of => String

attribute :ssl, :kind_of => [TrueClass, FalseClass], :default => false

