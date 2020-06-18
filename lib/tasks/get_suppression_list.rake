require 'net/imap'

task :get_suppression_list => :environment do
  puts 'Started task get_suppression_list'
  imap = Net::IMAP.new('imap.mail.us-east-1.awsapps.com', 993, true)
  imap.login('complaints@mailhawk.io', 'RaA_i@q7_Ra6A3')
  imap = Net::IMAP.new(ENV['IMAP_HOST'], 993, true)
  imap.login(ENV['IMAP_EMAIL'], ENV['IMAP_PASSWORD'])
  imap.list(ENV['IMAP_PASSWORD'], '*')
  imap.select('INBOX')
  imap.search(%w[NOT SEEN]).each do |message_id|
    begin
      puts "Getting mail with id #{message_id}"
      # envelope = imap.fetch(message_id, 'ENVELOPE')[0]
      body = imap.fetch(message_id, 'BODY[]')[0]
      mail = Mail.new(body.attr['BODY[]'])
      mail.attachments.each do |attachment|
        next unless attachment.filename.index('.txt') # skip until txt file found

        suppression_list = SuppressionList.new
        # Read each line and find Original-Rcpt-To
        attachment.read.each_line do |line|
          params = line.split(':', 2)
          puts params
          case params[0]
          when 'User-Agent'
            suppression_list.user_agent = params[1]&.strip
          when 'Arrival-Date'
            begin
              suppression_list.arrival_date = DateTime.parse(params[1]&.strip)
            rescue StandardError => e
              puts e.backtrace
              puts 'Unable to parse datetime'
            end
          when 'Source'
            suppression_list.source = params[1]&.strip
          when 'Original-Mail-From'
            suppression_list.mail_from = params[1]&.strip
          when 'Original-Rcpt-To'
            suppression_list.email = params[1]&.strip
          when 'Reported-Domain'
            suppression_list.reported_domain = params[1]&.strip
          when 'Source-Ip'
            suppression_list.source_ip = params[1]&.strip
          end
        end
        puts suppression_list.errors.full_messages unless suppression_list.save
      end
      imap.uid_store(message_id, '+FLAGS', [Net::IMAP::SEEN])
    rescue StandardError => e
      puts e.backtrace
    end
  end
  imap.logout
  imap.disconnect
  puts 'Completed task get_suppression_list'
end