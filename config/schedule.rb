set :output, Postal.log_root.join('cron.log')

set :environment, 'production'

every 5.minutes do
  rake 'get_suppression_list'
end
