require 'yaml'
require 'net/smtp'
require 'braincase/user'

module Braincase

  CONFIG_FILE = "/etc/braincase/config"
  HOSTNAME = `hostname -f`.chomp

  def Braincase.config
   
     raw = File.read( CONFIG_FILE )
    YAML.load( raw )["braincase"]
  end

  def Braincase.current_user
    Braincase::User.load `whoami`.chomp
  end

  def Braincase.is_root?
    Process.uid == 0
  end

  def Braincase.log_lines(log, lines, level=:error)
    
    if lines.class == String
      lines = lines.split("\n")
    end
    
    lines.each do |line|
      log.send(level, line) # call log.error line (unless caller sets level)
    end
  end

  def Braincase.validate_user(username)
    
    begin
      user = User.new username
    rescue
      return false
    end

    return true if
      user.in_linux? and
      user.has_braincase?
    
    false # invalid
  end

  def Braincase.validate_timestamp(timestamp)
    return true if timestamp == "current"
    return true if timestamp.match /\d{4}\.\d{2}\.\d{2}\.\d{2}.\d{2}.\d{2}/
    false # invalid
  end

  # allows us to send emails
  def Braincase.send_email(to,opts={})

    opts[:server]      ||= "localhost"
    opts[:from]        ||= c[:email][:from]
    opts[:from_alias]  ||= "Braincase"
    opts[:subject]     ||= "o dear"
    opts[:body]        ||= "o dear how did this get here i am not good with computer"

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