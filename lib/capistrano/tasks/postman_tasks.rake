namespace :postal do
  desc 'Postal start'
  task :status do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: "#{fetch(:stage)}" do
          execute '/opt/postal/current/bin/postal status'
        end
      end
    end
  end

  desc 'Postal start'
  task :start do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: "#{fetch(:stage)}" do
          execute '/opt/postal/current/bin/postal start'
        end
      end
    end
  end

  desc 'Postal restart'
  task :restart do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: "#{fetch(:stage)}" do
          execute '/opt/postal/current/bin/postal restart'
        end
      end
    end
  end

  desc 'Postal stop'
  task :stop do
    on roles(:app) do
      within "#{current_path}" do
        with rails_env: "#{fetch(:stage)}" do
          execute '/opt/postal/current/bin/postal stop'
        end
      end
    end
  end
end