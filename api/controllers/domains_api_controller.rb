controller :domains do
  friendly_name "Domains API"
  description "This API allows you to create and view domains on server"
  authenticator :server

  action :create do
    title "Create a domain"
    description "This action allows you to create domains"

    param :name, "Domain name (max 50)", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to create domain", :attributes => {:errors => "A hash of error details"}
    error 'DomainNameMissing', "Domain name is missing"
    error 'InvalidDomainName', "Domain name is invalid"
    error 'DomainNameExists', "Domain name already exists"
    error 'ReachedDomainLimit', "Domain limit reached"

    returns Hash, :structure => :domain

    action do
      domain = identity.server.domains.find_by_name(params.name)
      if domain.nil?
        server_limit = identity.server.server_limits.where(type: 'domain_limit').first
        if server_limit.present? && server_limit.limit_exhausted?
          error 'ReachedDomainLimit'
        else
          domain = Domain.new
          domain.server = identity.server
          domain.name = params.name
          domain.verification_method = 'DNS'
          domain.owner_type = Server
          domain.owner_id = identity.server.id
          domain.verified_at = Time.now
          if domain.save
            server_limit.increment!(:usage)
            structure :domain, domain, :return => true
          else
            error_message = domain.errors.full_messages.first
            if error_message == "Name is invalid"
              error "InvalidDomainName"
            else
              error "Error", error_message
            end
          end
        end
      else
        error 'DomainNameExists'
      end

    end
  end

  action :all do
    title "Query domain"
    description "This action allows you to query domain"

    action do
      identity.server.domains.map do |domain|
        structure :domain, domain
      end
    end
  end

  action :query do
    title "Query domain"
    description "This action allows you to query domain"

    param :name, "Domain name (max 50)", :required => false, :type => String

    error 'ValidationError', "The provided data was not sufficient to query domain", :attributes => {:errors => "A hash of error details"}
    error 'DomainNameMissing', "Domain name is missing"
    error 'DomainNotRegistered', "The domain not registered"

    returns Hash, :structure => :domain

    action do
      if params.name.present?
        domain = identity.server.domains.find_by_name(params.name)
        if domain.nil?
          error 'DomainNotRegistered'
        else
          structure :domain, domain, :return => true
        end
      else
        identity.server.domains.map do |domain|
          structure :domain, domain
        end
      end
    end
  end

  action :check do
    title "Check domain status"
    description "This action allows you to check domain status"

    param :name, "Domain name (max 50)", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to query domain", :attributes => {:errors => "A hash of error details"}
    error 'DomainNameMissing', "Domain name is missing"
    error 'DomainNotRegistered', "The domain not registered"

    returns Hash, :structure => :domain

    action do
      domain = identity.server.domains.find_by_name(params.name)
      if domain.nil?
        error 'DomainNotRegistered'
      else
        domain.check_dns(:manual)
        structure :domain, domain, :return => true
      end
    end
  end

  action :delete do
    title "Delete a domain"
    description "This action allows you to delete domain"

    param :name, "Domain name (max 50)", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to query domain", :attributes => {:errors => "A hash of error details"}
    error 'DomainNameMissing', "Domain name is missing"
    error 'DomainNotRegistered', "The domain not registered"
    error 'DomainNotDeleted', "Domain could not be deleted"

    returns Hash

    action do
      domain = identity.server.domains.find_by_name(params.name)
      if domain.nil?
        error 'DomainNotRegistered'
      elsif domain.delete
        server_limit = identity.server.server_limits.where(type: 'domain_limit').first
        server_limit.decrement!(:usage) if server_limit.present?
        {:message => "Domain deleted successfully"}
      else
        error 'DomainNotDeleted'
      end
    end
  end
end