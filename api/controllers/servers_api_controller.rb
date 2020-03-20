controller :servers do
  friendly_name "Servers API"
  description "This API allows you to perform CRUD on servers and set limits"
  authenticator :organisation

  action :build do
    title "Create a server"
    description "The build endpoint will create a new server, configure some initial settings from defaults (TBA) as well as create initial API credentials for the server."

    param :name, "Server name", :required => true, :type => String
    param :settings, "Server settings", :required => true, :type => Hash

    action do
      server = identity.servers.build(name: params.name, mode: params.settings['mode'])
      if server.save
        api_cred = server.credentials.create(type: 'API', name: "#{params.name} API key")
        server.credentials.create(type: 'SMTP', name: "#{params.name} SMTP key")
        server.server_limits.create(type: ServerLimit::TYPES[0], limit: params.settings['send_limit']) if params.settings['send_limit']
        server.server_limits.create(type: ServerLimit::TYPES[1], limit: params.settings['domain_limit']) if params.settings['domain_limit']
        { server_id: server.id, credential_key: api_cred.key }
      else
        error_message = server.errors.full_messages.first
        error "Unknown Error", error_message
      end
    end
  end

  action :update do
    title "update a server"
    description "We will need to update a server remotely in the event a customer upgrades their subscription plan. We should simply be able to pass a list of settings to update for the server."

    param :server_id, "Server id", :required => true, :type => Integer
    param :settings, "Server settings", :required => true, :type => Hash

    error 'ServerDoesNotExist', "Server does not exist"

    action do
      server = identity.servers.find(params.server_id)

      if server.present?
        if params.settings['mode'] && server.update(mode: params.settings['mode'])
          if params.settings['send_limit']
            send_limit = server.server_limits.find_or_initialize_by(type: ServerLimit::TYPES[0])
            send_limit.update(limit: params.settings['send_limit'])
          end
          if params.settings['domain_limit']
            domain_limit = server.server_limits.find_or_initialize_by(type: ServerLimit::TYPES[1])
            domain_limit.update(limit: params.settings['domain_limit'])
          end
          {
              message: "Server updated successfully."
          }
        else
          error_message = server.errors.full_messages.first
          error "Unknown Error", error_message
        end
      else
        error "ServerDoesNotExist"
      end
    end
  end

  action :suspend do
    title "suspend a server"
    description "In postal you can suspend a server, which prevents any mail from being sent. This will be useful if a customer doesn't pay their bill. This should suspend the server as you would suspending it from the UI."

    param :server_id, "Server id", :required => true, :type => Integer
    param :reason, "Suspend reason", :required => true, :type => String

    error 'ServerDoesNotExist', "Server does not exist"

    action do
      server = identity.servers.find(params.server_id)

      if server.present?
        if server.suspend(params.reason)
          {
              message: "Server suspended."
          }
        else
          error_message = server.errors.full_messages.first
          error "Unknown Error", error_message
        end
      else
        error "ServerDoesNotExist"
      end
    end
  end

  action :unsuspend do
    title "unsuspend a server"
    description "In postal you can unsuspend a server, which resumes mail sending."

    param :server_id, "Server id", :required => true, :type => Integer

    error 'ServerDoesNotExist', "Server does not exist"

    action do
      server = identity.servers.find(params.server_id)

      if server.present?
        if server.unsuspend
          {
              message: "Server unsuspended."
          }
        else
          error_message = server.errors.full_messages.first
          error "Unknown Error", error_message
        end
      else
        error "ServerDoesNotExist"
      end
    end
  end
end