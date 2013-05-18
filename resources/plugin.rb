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

attribute :repository, :kind_of => String, :required => true
attribute :revision, :kind_of => String, :default => "master"
attribute :redmine_dir, :kind_of => String, :required => true
attribute :rails_env, :kind_of => String, :default =>  "production"

attribute :gems, :kind_of => Array
