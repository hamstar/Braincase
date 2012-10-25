module Braincase
  class Dropbox

    def initialize(log, config=nil)
      @log=log
      @config=config

      @queues = @config[:autodropbox][:queues] if !@config.nil?
    end

    # deprecated
  	def self.enabled_for(user)
  	  File.directory? "#{user.home}/Dropbox"
  	end

    # deprecated
  	def self.installed_for(user)
  	  File.directory? "#{user.home}/.dropbox" and File.directory? "/home/#{user}/.dropbox-dist"
  	end

    def in_q?(q, user)

      raise StandardError, "Queue not found: #{q}" if !File.exist? q
      !`grep #{user.name} #{q}`.empty?
    end

    def enabled?(user)
      File.directory? "#{user.home}/Dropbox"
    end

    def disabled?(user)
      !enabled?(user) and 
        !in_q? @queues[:enabled], user and
        !in_q? @queues[:enable], user
    end

    def queue(user)
    
      return if !disabled? user
      raise StandardError, "#{user.name} has blank email" if user.email.nil?

      File.open( @queues[:enable], "a" ) { |f|
        f.puts "#{user.name}"
      }

      log.error "Failed to queue #{user.name}" if status user != "queued"
      log.info "Queued #{user.name}" if status user == "queued"

      status user == "queued"
    end

    def unqueue(user)
      #TODO
    end

    def disable!(user)
      #TODO
    end

    def status(user)
      return "enabled" if enabled? user
      return "emailed" if File.read( @queues[:enable] ).include? "#{user.name} emailed"
      return "queued" if in_q? @queues[:enable], user
      return "disabled" if disabled? user
      return "error"
    end

  	def setup(user)
      
      install
      url = get_url
      autostart

      subject = "Dropbox has been enabled on your Braincase Account"
      body = "Hi #{user.name}\n\nDropbox has been enabled on your Braincase account."
      body+= " You just need to enable it on your Dropbox account by visiting"
      body+= " the following link in your browser:\n\n\t#{url}"

      # all sorted, send the email
      Braincase.send_email user.email, {
        subject: subject,
        body: body
      }

      @log.info "URL sent to #{user.email}"
    end

    def install
      system "echo 'y' | dropbox.py start -i > /dev/null" # this tells the installation "yes"
    end

    def get_url

      url = `dropbox.py start`
      count = 0

      while !url.include? "https://www.dropbox.com/cli_link?host_id=" do
        sleep 3
        url=`dropbox.py start` # get the start message that provides the URL
        raise RuntimeError, "Dropbox URL unavailable" if count == 2
      end

      # extract and return the url
      url = url.split("\n")[1].chomp
      @log.info "Got URL #{url}"
      url
  	end

    def autostart
      system "dropbox.py autostart y"
    end
  end
end