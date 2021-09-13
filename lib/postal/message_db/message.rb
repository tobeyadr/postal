module Postal
  module MessageDB
    class Message

      class NotFound < Postal::Error
      end

      def self.find_one(database, query)
        query = {:id => query.to_i} if query.is_a?(Fixnum)
        if message = database.select('messages', :where => query, :limit => 1).first
          Message.new(database, message)
        else
          raise NotFound, "No message found matching provided query #{query}"
        end
      end

      def self.find(database, options = {})
        if messages = database.select('messages', options)
          if messages.is_a?(Array)
            messages.map { |m| Message.new(database, m) }
          else
            messages
          end
        else
          []
        end
      end

      def self.find_with_pagination(database, page, options = {})
        messages = database.select_with_pagination('messages', page, options)
        messages[:records] = messages[:records].map { |m| Message.new(database, m) }
        messages
      end

      attr_reader :database

      def initialize(database, attributes)
        @database = database
        @attributes = attributes
      end

      #
      # Return the server for this message
      #
      def server
        @database.server
      end

      #
      # Return the credential for this message
      #
      def credential
        @credential ||= self.credential_id ? Credential.find_by_id(self.credential_id) : nil
      end

      #
      # Return the route for this message
      #
      def route
        @route ||= self.route_id ? Route.find_by_id(self.route_id) : nil
      end

      #
      # Return the endpoint for this message
      #
      def endpoint
        @endpoint ||= begin
          if self.endpoint_type && self.endpoint_id
            self.endpoint_type.constantize.find_by_id(self.endpoint_id)
          elsif self.route && self.route.mode == 'Endpoint'
            self.route.endpoint
          end
        end
      end

      #
      # Return the credential for this message
      #
      def domain
        @domain ||= self.domain_id ? Domain.find_by_id(self.domain_id) : nil
      end

      #
      # Copy appropriate attributes from the raw message to the message itself
      #
      def copy_attributes_from_raw_message
        if self.raw_message
          self.subject = self.headers['subject']&.last.to_s[0,200]
          self.message_id = self.headers['message-id']&.last
          if self.message_id
            self.message_id = self.message_id.gsub(/.*</, '').gsub(/>.*/, '').strip
          end
        end
      end

      #
      # Return the timestamp for this message
      #
      def timestamp
        @timestamp ||= @attributes['timestamp'] ? Time.zone.at(@attributes['timestamp']) : nil
      end

      #
      # Return the time that the last delivery was attempted
      #
      def last_delivery_attempt
        @last_delivery_attempt ||= @attributes['last_delivery_attempt'] ? Time.zone.at(@attributes['last_delivery_attempt']) : nil
      end

      #
      # Return the hold expiry for this message
      #
      def hold_expiry
        @hold_expiry ||= @attributes['hold_expiry'] ? Time.zone.at(@attributes['hold_expiry']) : nil
      end

      #
      # Has this message been read?
      #
      def read?
        !!(loaded || clicked)
      end

      #
      # Add a delivery attempt for this message
      #
      def create_delivery(status, options = {})
        delivery = Delivery.create(self, options.merge(:status => status))
        hold_expiry = status == 'Held' ? Postal.config.general.maximum_hold_expiry_days.days.from_now.to_f : nil
        self.update(:status => status, :last_delivery_attempt => delivery.timestamp.to_f, :held => status == 'Held' ? 1 : 0, :hold_expiry => hold_expiry)
        delivery
      end

      #
      # Return all deliveries for this object
      #
      def deliveries
        @deliveries ||= begin
          @database.select('deliveries', :where => {:message_id => self.id}, :order => :timestamp).map do |hash|
            Delivery.new(self, hash)
          end
        end
      end

      #
      # Return all the clicks for this object
      #
      def clicks
        @clicks ||= begin
          clicks = @database.select('clicks', :where => {:message_id => self.id}, :order => :timestamp)
          if clicks.empty?
            []
          else
            links = @database.select('links', :where => {:id => clicks.map { |c| c['link_id'].to_i }}).group_by { |l| l['id'] }
            clicks.map do |hash|
              Click.new(hash, links[hash['link_id']].first)
            end
          end
        end
      end

      #
      # Return all the loads for this object
      #
      def loads
        @loads ||= begin
          loads = @database.select('loads', :where => {:message_id => self.id}, :order => :timestamp)
          loads.map do |hash|
            Load.new(hash)
          end
        end
      end

      #
      # Return all activity entries
      #
      def activity_entries
        @activity_entries ||= (deliveries + clicks + loads).sort_by(&:timestamp)
      end

      #
      # Provide access to set and get acceptable attributes
      #
      def method_missing(name, value = nil, &block)
        if @attributes.has_key?(name.to_s)
          @attributes[name.to_s]
        elsif name.to_s =~ /\=\z/
          @attributes[name.to_s.gsub('=', '').to_s] = value
        else
          nil
        end
      end

      #
      # Has this message been persisted to the database yet?
      #
      def persisted?
        !@attributes['id'].nil?
      end

      #
      # Save this message
      #
      def save
        save_raw_message
        persisted? ? _update : _create
        self
      end

      #
      # Update this message
      #
      def update(attributes_to_change)
        @attributes = @attributes.merge(database.stringify_keys(attributes_to_change))
        if persisted?
          @database.update('messages', attributes_to_change, :where => {:id => self.id})
        else
          _create
        end
      end

      #
      # Delete the message from the database
      #
      def delete
        if persisted?
          @database.delete('messages', :where => {:id => self.id})
        end
      end

      #
      # Return the headers
      #
      def raw_headers
        if self.raw_table
          @raw_headers ||= @database.select(self.raw_table, :where => {:id => self.raw_headers_id}).first&.send(:[], 'data') || ""
        else
          ""
        end
      end

      #
      # Return the full raw message body for this message.
      #
      def raw_body
        if self.raw_table
          @raw ||= @database.select(self.raw_table, :where => {:id => self.raw_body_id}).first&.send(:[], 'data') || ""
        else
          ""
        end
      end

      #
      # Return the full raw message for this message
      #
      def raw_message
        @raw_message ||= "#{raw_headers}\r\n\r\n#{raw_body}"
      end

      #
      # Set the raw message ready for saving later
      #
      def raw_message=(raw)
        @pending_raw_message = raw.force_encoding('BINARY')
      end

      #
      # Save the raw message to the database as appropriate
      #
      def save_raw_message
        if @pending_raw_message
          self.size = @pending_raw_message.bytesize
          date = Date.today
          table_name, headers_id, body_id = @database.insert_raw_message(@pending_raw_message, date)
          self.raw_table = table_name
          self.raw_headers_id = headers_id
          self.raw_body_id = body_id
          @raw = nil
          @raw_headers = nil
          @headers = nil
          @mail = nil
          @pending_raw_message = nil
          copy_attributes_from_raw_message
          @database.query("UPDATE `#{@database.database_name}`.`raw_message_sizes` SET size = size + #{self.size} WHERE table_name = '#{table_name}'")
        end
      end

      #
      # Is there a raw message?
      #
      def raw_message?
        !!self.raw_table
      end

      #
      # Return the plain body for this message
      #
      def plain_body
        mail&.plain_body
      end

      #
      # Return the HTML body for this message
      #
      def html_body
        mail&.html_body
      end

      #
      # Return the HTML body with any tracking links
      #
      def html_body_without_tracking_image
        html_body.gsub(/\<p class\=['"]ampimg['"].*?\<\/p\>/, '')
      end

      #
      # Return all attachments for this message
      #
      def attachments
        mail&.attachments || []
      end

      #
      # Return the headers for this message
      #
      def headers
        @headers ||= begin
          mail = Mail.new(self.raw_headers)
          mail.header.fields.each_with_object({}) do |field, hash|
            hash[field.name.downcase] ||= []
            begin
              hash[field.name.downcase] << field.decoded
            rescue Mail::Field::IncompleteParseError
              # Never mind, move on to the next header
            end
          end
        end
      end

      #
      # Return the recipient domain for this message
      #
      def recipient_domain
        self.rcpt_to ? self.rcpt_to.split('@').last : nil
      end

      #
      # Create a new item in the message queue for this message
      #
      def add_to_message_queue(options = {})
        QueuedMessage.create!(:message => self, :server_id => @database.server_id, :batch_key => self.batch_key, :domain => self.recipient_domain, :route_id => self.route_id, :manual => options[:manual]).id
      end

      #
      # Return a suitable batch key for this message
      #
      def batch_key
        case self.scope
        when 'outgoing'
          key = "outgoing-"
          key += self.recipient_domain.to_s
        when 'incoming'
          key = "incoming-"
          key += "rt:#{self.route_id}-ep:#{self.endpoint_id}-#{self.endpoint_type}"
        else
          key = nil
        end
        key
      end

      #
      # Return the queued message
      #
      def queued_message
        @queued_message ||= self.id ? QueuedMessage.where(:message_id => self.id, :server_id => @database.server_id).first : nil
      end

      #
      # Return the spam status
      #
      def spam_status
        return 'NotChecked' unless inspected == 1
        spam == 1 ? 'Spam' : 'NotSpam'
      end

      #
      # Has this message been held?
      #
      def held?
        status == 'Held'
      end

      #
      # Does this message have our DKIM header yet?
      #
      def has_outgoing_headers?
        !!(raw_headers =~ /^X\-Postal\-MsgID\:/i)
      end

      #
      # Add dkim header
      #
      def add_outgoing_headers
        headers = []
        if self.domain
          dkim = Postal::DKIMHeader.new(self.domain, self.raw_message)
          headers << dkim.dkim_header
        end
        headers << "X-Postal-MsgID: #{self.token}"
        append_headers(*headers)
      end

      #
      # Append a header to the existing headers
      #
      def append_headers(*headers)
        new_headers = headers.join("\r\n")
        new_headers = "#{new_headers}\r\n#{self.raw_headers}"
        @database.update(self.raw_table, {:data => new_headers}, :where => {:id => self.raw_headers_id})
        @raw_headers = new_headers
        @raw_message = nil
        @headers = nil
      end

      #
      # Return a suitable
      #
      def webhook_hash
        @webhook_hash ||= {
          :id => self.id,
          :token => self.token,
          :direction => self.scope,
          :message_id => self.message_id,
          :to => self.rcpt_to,
          :from => self.mail_from,
          :subject => self.subject,
          :timestamp => self.timestamp.to_f,
          :spam_status => self.spam_status,
          :tag => self.tag
        }
      end

      #
      # Mark this message as bounced
      #
      def bounce!(bounce_message)
        create_delivery('Bounced', :details => "We've received a bounce message for this e-mail. See <msg:#{bounce_message.id}> for details.")
        SendWebhookJob.queue(:main, :server_id => self.database.server_id, :event => "MessageBounced", :payload => {:_original_message => self.id, :_bounce => bounce_message.id})
      end

      #
      # Should bounces be sent for this message?
      #
      def send_bounces?
        self.bounce != 1 && self.mail_from.present?
      end

      #
      # Add a load for this message
      #
      def create_load(request)
        update('loaded' => Time.now.to_f) if loaded.nil?
        database.insert(:loads, {:message_id => self.id, :ip_address => request.ip, :user_agent => request.user_agent, :timestamp => Time.now.to_f})
        SendWebhookJob.queue(:main, :server_id => self.database.server_id, :event => 'MessageLoaded', :payload => {:_message => self.id, :ip_address => request.ip, :user_agent => request.user_agent})
      end

      #
      # Create a new link
      #
      def create_link(url)
        hash = Digest::SHA1.hexdigest(url.to_s)
        token = Nifty::Utils::RandomString.generate(:length => 8)
        database.insert(:links, {:message_id => self.id, :hash => hash, :url => url, :timestamp => Time.now.to_f, :token => token})
        token
      end

      #
      # Return a message object that this message is a reply to
      #
      def original_messages
        return nil unless self.bounce == 1
        other_message_ids = raw_message.scan(/\X\-Postal\-MsgID\:\s*([a-z0-9]+)/i).flatten
        if other_message_ids.empty?
          []
        else
          database.messages(:where => {:token => other_message_ids})
        end
      end

      #
      # Was thsi message sent to a return path?
      #
      def rcpt_to_return_path?
        !!(rcpt_to =~ /\@#{Regexp.escape(Postal.config.dns.custom_return_path_prefix)}\./)
      end

      #
      # Inspect this message
      #
      def inspect_message
        if result = MessageInspection.new(self.raw_message, self.scope&.to_sym)
          # Update the messages table with the results of our inspection
          update(:inspected => 1, :spam_score => result.filtered_spam_score,  :threat => result.threat?, :threat_details => result.threat_message)
          # Add any spam details into the spam checks database
          self.database.insert_multi(:spam_checks, [:message_id, :code, :score, :description], result.filtered_spam_checks.map { |d| [self.id, d.code, d.score, d.description]})
          # Return the result
          result
        end
      end

      #
      # Return all spam checks for this message
      #
      def spam_checks
        @spam_checks ||= self.database.select(:spam_checks, :where => {:message_id => self.id})
      end

      #
      # Cancel the hold on this message
      #
      def cancel_hold
        if self.status == 'Held'
          create_delivery('HoldCancelled', :details => "The hold on this message has been removed without action.")
        end
      end

      #
      # Parse the contents of this message
      #
      def parse_content
        parse_result = Postal::MessageParser.new(self)
        if parse_result.actioned?
          # Somethign was changed, update the raw message
          @database.update(self.raw_table, {:data => parse_result.new_body}, :where => {:id => self.raw_body_id})
          @raw = parse_result.new_body
          @raw_message = nil
        end
        update('parsed' => 1, 'tracked_links' => parse_result.tracked_links, 'tracked_images' => parse_result.tracked_images)
      end

      #
      # Has this message been parsed?
      #
      def parsed?
        self.parsed == 1
      end

      #
      # Should this message be parsed?
      #
      def should_parse?
        parsed? == false && headers['x-amp'] != 'skip'
      end

      private

      def _update
        @database.update('messages', @attributes.reject {|k,v| k == :id }, :where => {:id => @attributes['id']})
      end

      def _create
        self.timestamp = Time.now.to_f if self.timestamp.blank?
        self.status = 'Pending' if self.status.blank?
        self.token = Nifty::Utils::RandomString.generate(:length => 12) if self.token.blank?
        last_id = @database.insert('messages', @attributes.reject {|k,v| k == :id })
        @attributes['id'] = last_id
        @database.statistics.increment_all(self.timestamp, self.scope)
        Statistic.global.increment!(:total_messages)
        Statistic.global.increment!("total_#{self.scope}".to_sym)
        add_to_message_queue
      end

      def mail
        # This version of mail is only used for accessing the bodies.
        @mail ||= raw_message? ? Mail.new(raw_message) : nil
      end

    end
  end
end
