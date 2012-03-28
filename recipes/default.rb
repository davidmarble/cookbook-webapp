include_recipe "git::default"
require 'set'

node.default[:webapp][:deploy_root_owner] = node[:webapp][:deployer]
node.default[:webapp][:deploy_root_group] = node[:webapp][:deployer]

members = Set.new

if node.has_key?("deploy_root_group_members")
    members.merge(node[:deploy_root_group_members])
    # Just to be safe
    members.merge(node[:webapp][:deploy_root_owner])
else
    members.merge([node[:webapp][:deployer], node[:webapp][:deploy_root_owner], "root"])
end

if node.has_key?("additional_deploy_root_group_members")
    members.merge(node[:additional_deploy_root_group_members])
end

# Ensure all deploy_root_group_members exist
members.each do |username|
    utils_ensure_user username
end

# Ensure deploy_root_group exists
utils_ensure_group node[:webapp][:deploy_root_group] do
    members members.to_a
end

# Enable default rwx acl for deploy_root_group on deploy_root
# This installs /usr/local/bin/fixperms
utils_acl node[:webapp][:deploy_root]
bash "set default ACLs and fix existing perms on #{node[:webapp][:deploy_root]}" do
    code "/usr/local/bin/fixperms #{node[:webapp][:deploy_root_owner]} #{node[:webapp][:deploy_root_group]} #{node[:webapp][:deploy_root]}"
end

directory node[:webapp][:deploy_root] do
    owner node[:webapp][:deploy_root_owner]
    group node[:webapp][:deploy_root_group]
    mode "2775"
    recursive true
end

directory "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}" do
    owner node[:webapp][:deploy_root_owner]
    group node[:webapp][:deploy_root_group]
    mode "2775"
    recursive true
end

directory "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/logs" do
    owner node[:webapp][:deploy_root_owner]
    group node[:webapp][:deploy_root_group]
    mode "2775"
    recursive true
end

directory "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/emails" do
    owner node[:webapp][:deploy_root_owner]
    group node[:webapp][:deploy_root_group]
    mode "2775"
    recursive true
end

directory "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/storage" do
    owner node[:webapp][:deploy_root_owner]
    group node[:webapp][:deploy_root_group]
    mode "2775"
    recursive true
end

directory "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/static_pages" do
    owner node[:webapp][:deploy_root_owner]
    group node[:webapp][:deploy_root_group]
    mode "2775"
    recursive true
end

directory "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/site_media" do
    owner node[:webapp][:deploy_root_owner]
    group node[:webapp][:deploy_root_group]
    mode "2775"
    recursive true
end

directory "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/site_media/static" do
    owner node[:webapp][:deploy_root_owner]
    group node[:webapp][:deploy_root_group]
    mode "2775"
    recursive true
end

directory "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/site_media/media" do
    owner node[:webapp][:deploy_root_owner]
    group node[:webapp][:deploy_root_group]
    mode "2775"
    recursive true
end

# Check if using a local vagrant repo. 
# If not, grab code with branch and tag specified.
# If no tag specified, default to HEAD.

node.default[:webapp][:branch_or_tag] = "master"

if !(node.attribute?("using_vagrant") and node[:using_vagrant].attribute?("use_local_repo") and node[:using_vagrant][:use_local_repo])
    script "clone or pull #{node[:webapp][:app_name]} repo" do
        interpreter "bash"
        user node[:webapp][:deployer]
        cwd "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}"
        code <<-EOH
        if ! [ -d #{node[:webapp][:branch_or_tag]} ]; then
            git clone --recursive #{node[:webapp][:repo]} #{node[:webapp][:branch_or_tag]}
            cd #{node[:webapp][:branch_or_tag]} && git checkout #{node[:webapp][:branch_or_tag]}
        else
            cd #{node[:webapp][:branch_or_tag]} && git pull && git submodule update --init --recursive
        fi
        EOH
    end
end

if node[:webapp].attribute?("stop_command")
    script "stop #{node[:webapp][:app_name]}" do
        interpreter "bash"
        user "root"
        code <<-EOH
        su -l -c 'if [ -f $HOME/.aliases ]; then source $HOME/.aliases && #{node[:webapp][:stop_command]} > /dev/null 2>&1; else #{node[:webapp][:stop_command]} > /dev/null 2>&1; fi' root > /dev/null
        EOH
    end
end

# If not using a local vagrant repo, link the deployed branch/tag to /<deploy_root>/<app_name>/live 
if !(node.attribute?("using_vagrant") and node[:using_vagrant].attribute?("use_local_repo") and node[:using_vagrant][:use_local_repo])
    script "ln -s #{node[:webapp][:branch_or_tag]} to live" do
        interpreter "bash"
        user node[:webapp][:deployer]
        cwd "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}"
        code <<-EOH
        if [ -s live ]; then
            rm live
        fi
        ln -s #{node[:webapp][:branch_or_tag]} live
        EOH
    end
end

# Be sure to implement a reload script in your webapp type recipe.
# See 'if node[:webapp].attribute?("start_command")' in webapp:python
if node["webapp"].attribute?("python")
    include_recipe "webapp::python"
end
