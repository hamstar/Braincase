require 'yaml'
require 'net/smtp'

module Braincase

  CONFIG_FILE = "/etc/braincase/config"
  HOSTNAME = `hostname -f`.chomp

  def Braincase.config(section='')
    
    raw = File.read( CONFIG_FILE )
    yml = YAML.load( raw )["braincase"]

    # Return the section or the whole thing
    if !section.empty?
      yml[section]
    else
  	  yml
  	end
  end

  def Braincase.is_root?
    `echo $USER`.chomp == "root"
  end

  # allows us to send emails
  def Braincase.send_email(to,opts={})
    opts[:server]      ||= "localhost"
    opts[:from]        ||= "braincase@#{Braincase::HOSTNAME}"
    opts[:from_alias]  ||= "Braincase"
    opts[:subject]     ||= "Message from Braincase"
    opts[:body]        ||= "Nothing to report!"

    msg = <<END_OF_MESSAGE
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{to}>
Subject: #{opts[:subject]}

#{opts[:body]}
END_OF_MESSAGE

    Net::SMTP.start(opts[:server]) do |smtp|
      smtp.send_message msg, opts[:from], to
    end
  end
end