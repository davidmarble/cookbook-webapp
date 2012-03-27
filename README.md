# Description

Chef cookbook for deploying a web application.

**NOTE:** Make sure to rename this to `webapp` if you clone it or incorporate 
it as a git submodule in your cookbooks.

# Requirements

## Cookbooks

* **utils** - https://github.com/davidmarble/cookbook-utils
* **git**
* **python** - for webapp::python

# Usage

## Recipes

### webapp

Here is an example webapp configuration in JSON. Each option is explained 
below along with a walkthrough of recipe execution.

    "webapp": {
        "app_name": "consource",
        "repo": "git@github.com:spurfly/consource.git",
        "branch_or_tag": "master",
        "deployer": "cs",
        "deploy_root": "/var/www",
        "deploy_root_group": "www-pub",
        "deploy_root_owner": "www-data",
        "deploy_root_group_members": ["cs", "root", "www-data"], 
        "python": {
            "django": {
                "options": ["south"]
            },
            "virtualenv_reqs": "requirements/all.txt",
            "gunicorn": {
                "production": "workers/prod.py",
                "debug": "workers/debug.py"
            }
        },
        "stop_command": "consource stop",
        "start_command": "consource compile && consource start"
    }

* `app_name` - Name for the web application 
* `repo` - Git repository to clone / pull from. 
* `branch_or_tag` (default="master") - Git branch or tag for this server to 
deploy
* `deployer` - User with permissions to conduct deployment operations
* `deploy_root` - Base directory for webapp. `app_name` is concatenated.
* `deploy_root_group` & `deploy_root_owner` (optional) - Owner of 
`deploy_root`. The group write bit will be set so that all users of 
`deploy_root_group` will be able to edit webapp files. These default to 
the value of `deployer`.
* `deploy_root_group_members` - Optional additional users to add to the 
deploy_root_group. 
* `python` - See webapp::python recipe.
* `stop_command` - Shell command to call before a deployment. Can include 
aliases and scripts accessible to `root` upon login. Use this to stop 
processes if needed.
* `start_command` - Shell command to call after all other deployment 
operations. Can include aliases and scripts accessible to `root` upon login. 
Use this to restart or reload processes.

#### Walkthrough of the webapp recipe

1. All users and groups referenced in configuration are assured to exist 
via providers from the required **utils** cookbook.

2. ACL is enabled for {deploy_root}, the owner and group is set to 
{deploy_root_owner}:{deploy_root_group}, and the group write bit is set 
for {deploy_root} and all existing sub-directories.

3. The following directory structure is created:

        {deploy_root}/{app_name}
        {deploy_root}/{app_name}/logs - keep site-specific logs in one place
        {deploy_root}/{app_name}/emails - usually for development
        {deploy_root}/{app_name}/storage
        {deploy_root}/{app_name}/static_pages - add a rewrite rule to nginx for non-dynamic pages
        {deploy_root}/{app_name}/site_media
        {deploy_root}/{app_name}/site_media/static - site assets (images, js, css)
        {deploy_root}/{app_name}/site_media/media - user uploaded assets

4. If `node["using_vagrant"]["use_local_repo"]` is undefined or false, 
the git repository `repo` is cloned or pulled to 
`{deploy_root}/{app_name}/{branch_or_tag}` with the active branch set to 
`branch_or_tag`.

5. `stop_command` is run from a bash shell as root

6. A soft link `{deploy_root}/{app_name}/live` is created or changed to point 
to `{deploy_root}/{app_name}/{branch_or_tag}`

7. A webapp type-specific recipe is called depending on configuration. 
Currently this only supports python projects via the `node["webapp"]["python"]` 
parameters as explained in the webapp::python recipe.

8. `start_command` implementation must be defined in the webapp type-specific 
recipe. An example can be found in the webapp::python recipe.

### webapp::python

Don't call this recipe directly. It is invoked if your webapp configuration 
defines `node["webapp"]["python"]` and its required items. 

Example:
    
    "python": { // Parameters also used for python cookbook
        "WORKON_HOME": "/var/www/envs"
        . . . // See python cookbook for other parameters
    },
    . . .
    "webapp": {
        . . .
        "python": {
            "django": {
                "options": ["south"]
            },
            "virtualenv_reqs": "requirements/all.txt"
        },
        . . .
    }

* `django` - If defined, calls syncdb with either the virtualenvwrapper version 
of python (if `node["python"]["WORKON_HOME"]` is defined) or the first python 
in `deployer`'s path.
* `django => options` - A list of django options. Currently this only supports 
"south", which if included runs migrations using either the virutalenvwrapper 
python or the first python in `deployer`'s path.
* `virtualenv_reqs` - A file location for pip requirements to be installed. 
This calls `pip install -r`, *not* `pip intall -rU`, so no upgrades are 
performed. 

    * **Important note** - This feature currently relies on 
    **virtualenvwrapper** having been installed and having 
    `node["python"]["WORKON_HOME"]` set to WORKON_HOME 
    for your installation of virtualenvwrapper. The user `deployer` must have 
    access to this directory. You can install virtualenvwrapper with my custom 
    python cookbook (https://github.com/davidmarble/cookbook-python), which 
    also makes use of `node["python"]["WORKON_HOME"]`. 
    
        If `node["python"]["WORKON_HOME"]` is set and virtualenvwrapper is 
        installed, a virtualenv is created in 
        `#{node[:python][:WORKON_HOME]}/#{node[:webapp][:app_name]}` and 
        requirements are installed there.


# License and Author

Author:: David Marble (<davidmarble@gmail.com>)

Copyright:: 2012, David Marble

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
