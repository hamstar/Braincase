require 'yaml'
require 'net/smtp'

module Braincase

  CONFIG_FILE = "/etc/braincase/config"
  HOSTNAME = `hostname -f`.chomp

  def Braincase.config
    
    raw = File.read( CONFIG_FILE )
    YAML.load( raw )["braincase"]
  end

  def Braincase.current_user
    user.home = User.new `whoami`.chomp

    conf = YAML.load( File.read( "#{user.home}/.braincase/config" ) )[user.name]
    user.email = conf[:email]
    user.full_name = conf[:full_name]
    user.groups = conf[:groups]

    user
  end

  def Braincase.is_root?
    Process.uid == 0
  end

  # allows us to send emails
  def Braincase.send_email(to,opts={})

    c = Braincase.config

    opts[:server]      ||= c[:email][:address]
    opts[:from]        ||= c[:email][:from]
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