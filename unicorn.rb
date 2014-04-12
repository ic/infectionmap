# Launch with:
#
# unicorn -c path/to/unicorn.rb -E development -D
#

require 'fileutils'

# set path to app that will be used to configure unicorn,
# note the trailing slash in this example
wdir = File.expand_path('.', File.dirname(__FILE__)) + '/'

worker_processes 2
working_directory wdir

# This loads the application in the master process before forking
# worker processes
# Read more about it here:
# http://unicorn.bogomips.org/Unicorn/Configurator.html
preload_app true

timeout 30

# Specify path to socket unicorn listens to,
# we will use this in our nginx.conf later
run_path = '/var/run/crowdy'
FileUtils.mkdir_p run_path
listen "#{run_path}/unicorn.sock", :backlog => 64

# Set process id path
pid_path = '/var/lock/crowdy'
FileUtils.mkdir_p pid_path
pid "#{pid_path}/unicorn.pid"

# Set log file paths
log_path = '/var/log/crowdy'
FileUtils.mkdir_p log_path
stderr_path "#{log_path}/unicorn.stderr.log"
stdout_path "#{log_path}/unicorn.stdout.log"

before_fork do |server, worker|
  # This option works in together with preload_app true setting
  # What is does is prevent the master process from holding
  # the database connection
  defined?(ActiveRecord::Base) and
  ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  # Here we are establishing the connection after forking worker
  # processes
  defined?(ActiveRecord::Base) and
  ActiveRecord::Base.establish_connection
end

