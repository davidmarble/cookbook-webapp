include_recipe "utils::disable_hg_cert_checking"
include_recipe "python::default"

python_base = ""

if node.attribute?("using_vagrant") and node[:using_vagrant].attribute?("use_local_repo") and node[:using_vagrant][:use_local_repo]
    webapp_user = "vagrant" 
else
    webapp_user = node[:webapp][:deployer] 
end

if node.attribute?("python") and node[:python].has_key?("WORKON_HOME")
    # Set python_base to virtualenvwrapper WORKON_HOME for this webapp
    python_base = "#{node[:python][:WORKON_HOME]}/#{node[:webapp][:app_name]}/bin/"

    python_virtualenv "#{node[:python][:WORKON_HOME]}/#{node[:webapp][:app_name]}" do
        owner node[:webapp][:deploy_root_owner]
        group node[:webapp][:deploy_root_group]
        action :create
    end

    if node[:webapp].attribute?("python") and node[:webapp][:python].attribute?("virtualenv_reqs")

        # This is unused because it installs using root
        # python_pip "-U -r /var/www/#{node[:app_name]}/live/#{node[:req_file]}" do
            # virtualenv "/var/www/envs/#{node[:virtualenv]}"
            # action :install
        # end
        
        script "Install Requirements" do
            interpreter "bash"
            user "root"
            cwd "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/live"
            code <<-EOH
            git config --global http.sslverify false
            su -l -c '#{node[:python][:WORKON_HOME]}/#{node[:webapp][:app_name]}/bin/pip install -r #{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/live/#{node[:webapp][:python][:virtualenv_reqs]}' #{webapp_user} 
            EOH
        end
    end
end

# TODO: Run syncdb (possibly for the first time) and restart needed services
if node[:webapp][:python].attribute?("django")
    
    script "syncdb" do
        interpreter "bash"
        user webapp_user
        cwd "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/live" 
        code <<-EOH
        #{python_base}python manage.py syncdb --noinput
        EOH
    end
    if node[:webapp][:python][:django][:options].include?("south")
        script "run migrations" do
            interpreter "bash"
            user webapp_user
            cwd "#{node[:webapp][:deploy_root]}/#{node[:webapp][:app_name]}/live" 
            code <<-EOH
            #{python_base}python manage.py migrate
            EOH
        end
    end
end

if node[:webapp].attribute?("start_command")
    script "reload #{node[:webapp][:app_name]}" do
        interpreter "bash"
        user "root"
        code <<-EOH
        su -l -c 'if [ -f $HOME/.aliases ]; then source $HOME/.aliases && #{node[:webapp][:start_command]} > /dev/null 2>&1; else #{node[:webapp][:start_command]} > /dev/null 2>&1; fi' #{webapp_user} > /dev/null
        EOH
    end
end

# OLD WAY
# Problems with non-interactive logins
# http://tickets.opscode.com/browse/CHEF-2288
# Nothing else seemed able to trigger .bashrc
# properly. Env variables would be set, but virtualenvwrapper.sh
# wouldn't get called (or at least wouldn't create directories).
# not needed:
#   su -l -c 'source ~#{node[:deployer]}/.bashrc' node[:deployer]
#
# script "Install Requirements" do
    # interpreter "bash"
    # user "root"
    # cwd "/var/www/#{node[:app_name]}/live"
    # code <<-EOH
# su -l -c 'mkvirtualenv s; /var/www/envs/#{node[:virtualenv]}/bin/pip install -U -r /var/www/#{node[:app_name]}/live/#{node[:req_file]}' #{node[:deployer]}
    # EOH
# end
