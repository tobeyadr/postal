controller :webhooks do
  friendly_name "Webhooks API"
  description "This API allows you to perform CRUD on webhooks"
  authenticator :server

  action :create do
    title "Register a new webhook"
    description "Use the same authentication method as the Domains API. Webhooks should only be changed or modified if the server_id of the webhook matches the server_id of the credential used to make the request."

    param :name, "Webhook name", :required => true, :type => String
    param :url, "Webhook url", :required => true, :type => String
    param :all_events, "Webhook for all events", :required => true, :type => Integer
    param :events, "Webhook events", required: false, :type => Array

    action do
      webhook = identity.server.webhooks.build(name: params.name, url: params.url, all_events: params.all_events, events: params.events)
      if webhook.save
        { webhook_id: webhook.id, message: "webhook created" }
      else
        error_message = webhook.errors.full_messages.first
        error "Error", error_message
      end
    end
  end

  action :update do
    title "Update the events of a webhook"
    description "Update the events of a webhook given the webhook URL. In this case we will not be using the webhook ID."

    param :url, "Webhook url", :required => true, :type => String
    param :all_events, "Webhook for all events", :required => false, :type => Integer, default: 0
    param :events, "Webhook events", required: false, :type => Array, default: []

    error 'WebhookDoesNotExist', "Webhook does not exist"

    action do
      webhook = identity.server.webhooks.find_by(url: params.url)

      if webhook.present?
        if webhook.update events: params.events, all_events: params.all_events
          { message: "Webhook updated successfully" }
        else
          error_message = webhook.errors.full_messages.first
          error "Error", error_message
        end
      else
        error "WebhookDoesNotExist"
      end
    end
  end

  action :delete do
    title "Delete a webhook"
    description "Delete a webhook given the webhook url."

    param :url, "Webhook url", :required => true, :type => String

    error 'WebhookDoesNotExist', "Webhook does not exist"

    action do
      webhook = identity.server.webhooks.find_by(url: params.url)

      if webhook.present?
        webhook.destroy
        { message: "Webhook deleted." }
      else
        error "WebhookDoesNotExist"
      end
    end
  end
end