module Braincase
  class Dropbox

    def initialize(log)
      @log=log
    end

    # Deprecated
  	def self.enabled_for(user)
  	  self.enabled? user
  	end

    # Deprecated
  	def self.installed_for(user)
  	  self.installed? user
  	end

    def self.enabled?(user)
      File.directory? "#{user.home}/Dropbox"
    end

    def self.installed?(user)
      File.directory? "#{user.home}/.dropbox" and File.directory? "/home/#{user}/.dropbox-dist"
    end

    def self.queued?(user)
      File.read(Braincase.config[:autodropbox][:queues][:enable]).include? user.name
    end

    def self.emailed?(user)
      File.read(Braincase.config[:autodropbox][:queues][:enable]).include? "#{user.name} emailed"
    end

    def self.queue(user)
      File.open(Braincase.config[:autodropbox][:queues][:enable], "a") {|f|
        f.puts(user.name)
      }
    end

    def self.status?(user)
      return "enabled" if self.enabled? user
      return "emailed" if self.emailed? user
      return "queued" if self.queued? user
      return "installed but not enabled" if self.installed? user
      return "disabled"
    end

  	def setup(user, type)
      
      @user=user

      case type
      when :cli
        return setup_cli
      when :email
        setup_email
      else
        raise RuntimeError, "Unknown setup type #{type}"
      end
    end

    private

    def setup_cli
      
      install
      url = get_url
      autostart
      
      "Link DropBox to this account by pasting the following link in your browser:\n#{url}"
    end

    def setup_email
      
      install
      url = get_url
      autostart

      subject = "Dropbox has been enabled on your Braincase Account"
      body = "Hi #{@user.name}\n\nDropbox has been enabled on your Braincase account."
      body+= " You just need to enable it on your Dropbox account by visiting"
      body+= " the following link in your browser:\n\n\t#{url}"

      # all sorted, send the email
      Braincase.send_email @user.email, {
        subject: subject,
        body: body
      }

      @log.info "URL sent to #{@user.email}"
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