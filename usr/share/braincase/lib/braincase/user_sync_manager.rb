require 'json'

module Braincase
  class UserSyncManager

    def initialize( creator, config, log, user, md5 )

      @creator=creator
      @config=config
      @log=log
      @user=user
      @md5=md5
    end

    def sync

      return false if !users_changed?

      @log.info "The user file has changed, doing a sync"

      # Run through each user and create ones that are missing
      File.open(@config[:users_file],"r").each do |line|
        
        begin

          user = @user.build line # build user from a line in the users file
          next if user.has_braincase?
          
          @creator.create user
          @log.info "Created #{user.name} in system"

          check_for_notify_email user
        rescue RuntimeError => e
        
          @log.error e.message
        end
      end

      # write new hash to disk
      File.open(@config[:usersync][:users_hash], 'w'){|f| f.write(@new_hash)}
    end

    def users_changed?

      old_hash = File.read( @config[:usersync][:users_hash] )
      @new_hash = @md5.hexdigest(File.read(@config[:users_file]))
      
      @log.info "old hash: #{old_hash}"
      @log.info "new hash: #{@new_hash}"
      
      old_hash != @new_hash
    end

    def check_for_notify_email(user)
      
      saved_email = "#{@config[:mailq]}/#{user.name}.txt"
      
      if !File.exist? saved_email
        @log.info "#{user.name} does not have a saved email"
        return false
      end

      saved_email = JSON.load( File.read( saved_email ) )

      secret = extract_password saved_email["body"]
      user.set_linux_password secret
      @log.info "Set password for #{user.name}"
      
      notify_user saved_email
      @log.info "#{user.name} was sent their details via email"
    end

    def extract_password(body)
      m = body.match(/Password : (.*)\n\n/)
      
      if m.nil?
        raise RuntimeError, "Couldn't extact password from email for #{user.name}, they are still waiting for notification"
      end

      m[1]
    end

    def notify_user(json)
      send_email json["to"], {
        :body => json["body"],
        :subject => json["subject"]
      }
    end
  end
end