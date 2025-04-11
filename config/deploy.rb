lock "~> 3.17.0"

set :application, "ci-cd"
set :repo_url, "git@github.com:shubhamjain108-lab/ci-cd.git"
set :deploy_to, "/var/www/#{fetch(:application)}"

# RVM setup
set :rvm_type, :user
set :rvm_ruby_version, '3.2.2' # or your Ruby version

# Linked files & directories
append :linked_files, "config/master.key"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

set :keep_releases, 5

# Puma config
set :puma_user, fetch(:user)
set :puma_systemd_unit_name, "puma_#{fetch(:application)}"
set :puma_threads, [4, 16]
set :puma_workers, 2
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"

