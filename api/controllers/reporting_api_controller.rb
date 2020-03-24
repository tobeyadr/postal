controller :reporting do
  friendly_name "Reporting API"
  description "This API allows you to fetch reports on server"
  authenticator :server

  action :query do
    title "Query  analytics between two times"
    description "Query any and all available reporting for the server."

    param :duration, "Integer value of duration", :required => true, :type => Integer
    param :type, "hourly, daily, monthly, yearly", :required => true, :type => String

    error 'DurationInvalid', "Duration can only have value > 0"
    error 'TypeInvalid', "Type can only have value hourly, daily, monthly, yearly"

    action do
      if params.duration.positive?
        if %w[hourly, daily, monthly, yearly].include? params.type
          graph_data = identity.server.message_db.statistics.get(params.type.to_sym, [:incoming, :outgoing, :spam, :bounces, :held], Time.now, params.duration)
          first_date = graph_data.first.first
          last_date = graph_data.last.first
          graph_data = graph_data.map(&:last)
          { first_date: first_date, last_date: last_date, graph_data: graph_data }
        else
          error 'TypeInvalid'
        end
      else
        error 'DurationInvalid'
      end
    end
  end
end