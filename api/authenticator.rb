authenticator :server do
  friendly_name "Server Authenticator"
  header "X-Server-API-Key", "The API token for a server that you wish to authenticate with.", :example => 'f29a45f0d4e1744ebaee'
  error 'InvalidServerAPIKey', "The API token provided in X-Server-API-Key was not valid.", :attributes => {:token => "The token that was looked up"}
  error 'ServerSuspended', "The mail server has been suspended"
  lookup do
    if key = request.headers['X-Server-API-Key']
      credential = Credential.where(:type => 'API', :key => key).first
      if credential.present?
        if credential.server.suspended?
          error 'ServerSuspended'
        else
          credential.use
          credential
        end
      else
        error 'InvalidServerAPIKey', :token => key
      end
    end
  end
  rule :default, "AccessDenied", "Must be authenticated as a server." do
    identity.is_a?(Credential)
  end
end

authenticator :organisation do
  friendly_name "Organisation Authenticator"
  header "X-Organization-Key", "The key for a organisation that you wish to authenticate with.", :example => 'f29a45f0d4e1744ebaee'
  error 'InvalidOrganisationKey', "The API token provided in X-Organization-Key was not valid.", :attributes => {:token => "The token that was looked up"}
  lookup do
    if key = request.headers['X-Organization-Key']
      organisation = Organization.where(key: key).first
      if organisation.present?
        organisation.use
        organisation
      else
        error 'InvalidServerAPIKey', :token => key
      end
    end
  end
  rule :default, "AccessDenied", "Must be authenticated as a organisation." do
    identity.is_a?(Organization)
  end
end

authenticator :anonymous do
  rule :default, "MustNotBeAuthenticated", "Must not be authenticated." do
    identity.nil?
  end
end
