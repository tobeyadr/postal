controller :messages do
  friendly_name "Messages API"
  description "This API allows you to access message details"
  authenticator :server

  action :search do
    title "Search messages"
    description "Search messages"
    # param :status, "The status of messages", :type => [String, Array], :required => false
    param :search, "The search filter", :type => String, :required => false
    param :from, "The from email", :type => String, :required => false
    param :to, "The recipient email", :type => String, :required => false
    param :before, "The before filter", :type => String, :required => false
    param :after, "The after filter", :type => String, :required => false
    param :order, "The order direction", :type => String, :required => false
    param :orderby, "The order by", :type => String, :required => false
    param :limit, "The limit of the messages", :type => Integer, :required => false
    param :offset, "The offset of the messages", :type => Integer, :required => false
    returns Array, :structure => :message, :structure_opts => {:paramable => {:expansions => false}}

    action do
      begin
        where = Hash.new
        where[:status] = params.status if params.status.present?
        where[:mail_from] = params.from if params.from.present?
        where[:rcpt_to] = params.to if params.to.present?
        where[:subject] = { :like => params.search } if params.search.present?

        time_range = {}
        if params.before.present?
          time_range = time_range.merge(:less_than_or_equal_to => params.before.to_datetime.to_i)
        end
        if params.after.present?
          time_range = time_range.merge(:greater_than_or_equal_to => params.after.to_datetime.to_i)
        end
        where[:timestamp] = time_range

        messages = identity.server.message_db.select(
          'messages',
          {
            limit: params.limit || 20,
            offset: params.offset || 0,
            order: params.orderby || 'id',
            direction: params.order || 'ASC',
            where: where
          }
        )


        messages.map do |d|
          obj = identity.server.message_db.new_message(d)
          structure :message, obj
        end
        # {messages: messages}
      rescue Postal::MessageDB::Message::NotFound => e
        error "MessageNotFound #{e}"
      end
    end
  end

  action :message do
    title "Return message details"
    description "Returns all details about a message"
    param :id, "The ID of the message", :type => Integer, :required => true
    returns Hash, :structure => :message, :structure_opts => {:paramable => {:expansions => false}}
    error 'MessageNotFound', "No message found matching provided ID", :attributes => {:id => "The ID of the message"}
    action do
      begin
        message = identity.server.message(params.id)
      rescue Postal::MessageDB::Message::NotFound => e
        error 'MessageNotFound', :id => params.id
      end
      structure :message, message, :return => true
    end
  end

  action :deliveries do
    title "Return deliveries for a message"
    description "Returns an array of deliveries which have been attempted for this message"
    param :id, "The ID of the message", :type => Integer, :required => true
    returns Array, :structure => :delivery, :structure_opts => {:full => true}
    error 'MessageNotFound', "No message found matching provided ID", :attributes => {:id => "The ID of the message"}
    action do
      begin
        message = identity.server.message(params.id)
      rescue Postal::MessageDB::Message::NotFound => e
        error 'MessageNotFound', :id => params.id
      end
      message.deliveries.map do |d|
        structure :delivery, d
      end
    end
  end

end
