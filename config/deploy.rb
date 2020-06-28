# config valid for current version and patch releases of Capistrano
lock '~> 3.14.1'

set :application, 'postal'
set :repo_url, 'git@github.com:tobeyadr/postal.git'

set :deploy_to, '/opt/postal'

set :keep_releases, 5

set :rails_assets_groups, 'assets'
set :bundle_path, '/opt/postal/vendor/bundle'
set :bundle_without, 'development'
set :bundle_flags, nil
set :bundle_jobs, 2
set :bundle_binstubs, nil

append :linked_dirs, 'bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets',
       'public/system', 'public/uploads', 'vendor/bundle'

after 'deploy', 'postal:restart'


# Create linked directory in shared folder and paste all bin files
# Create link between files sudo ln -s /opt/postal/app/bin/postal /usr/bin/postal