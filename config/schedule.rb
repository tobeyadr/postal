set :output, '/opt/postal/log/cron.log'

set :environment, 'production'

every 5.minutes do
  rake 'get_suppression_list'
end
