controller :credentials do
  friendly_name "Credentials API"
  description "This API allows you to perform CRUD on credential and set limits"
  authenticator :server

  action :create do
    title "Create a Credential"
    description "This action allows you to create credentials"

    param :name, "Credential name", :required => true, :type => String
    param :type, "Credential type (API, MASTER, SMTP)", :required => true, :type => String
    param :credential_limits, "Credential Limits Array", :required => true, :type => Array

    action do
      credential = Credential.new
      credential.server = identity.server
      credential.name = params.name
      credential.type = params.type
      credential.credential_limits_attributes = params.credential_limits
      if credential.save!
        {
          credential_key: credential.key,
          credential_id: credential.id
        }
      else
        error_message = credential.errors.full_messages.first
        error "Unknown Error", error_message
      end
    end
  end

  action :update do
    title "Update a Credential"
    description "This action allows you to update credentials"

    param :credential_id, "Credential id", :required => true, :type => Integer
    param :credential_limits, "Credential Limits Array", :required => true, :type => Array

    error 'CredentialNotFound', "Credential not found"

    action do
      credential = Credential.find_by(id: params.credential_id)
      if credential.present?
        params.credential_limits.each do |cl|
          credential_limit = credential.credential_limits.find_or_initialize_by(type: cl['type'])
          credential_limit.limit = cl['limit'] || credential_limit.limit
          credential_limit.usage = cl['usage'] || credential_limit.usage
          credential_limit.save
        end
        {
          success: true
        }
      else
        error 'CredentialNotFound'
      end
    end
  end

  action :limits do
    title "Get limits for a Credential"
    description "This action allows you to get limts for credentials"

    action do
      credential_limits = identity.credential_limits
      credential_limits.map do |cl|
        {
            type: cl.type,
            limit: cl.limit,
            usage: cl.usage
        }
      end
    end
  end
end