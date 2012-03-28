#
# Author:: David Marble (<davidmarble@gmail.com>)
# Cookbook Name:: webapp
# Attribute:: default
#
# Copyright 2012, David Marble
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

default["webapp"]["python"]["django"]["options"] = []
default["webapp"]["deploy_root_owner"] = node["webapp"]["deployer"]
default["webapp"]["deploy_root_group"] = node["webapp"]["deployer"]
default["webapp"]["branch_or_tag"] = "master"
