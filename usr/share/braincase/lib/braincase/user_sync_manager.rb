require 'json'
require 'braincase/exceptions'

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

      @log.debug "The user file has changed, doing a sync"

      # Run through each user and create ones that are missing
      File.open(@config[:users_file],"r").each do |line|

        begin
          user = @user.build line # build user from a line in the users file
          next if user.has_braincase?
          
          @creator.create user
          @log.info "Created #{user.name} in system"

          check_for_notify_email user

        rescue PasswordMatchError => e
          @log.error e.message

        rescue PasswordSetError => e
          @log.error e.message

        rescue RestrictedUserError
          @log.debug "Skipping restricted user in #{line}"

        end
      end

      # write new hash to disk
      File.open(@config[:usersync][:users_hash], 'w'){|f| f.write(@new_hash)}
    end

    def users_changed?

      old_hash = File.read( @config[:usersync][:users_hash] )
      @new_hash = @md5.hexdigest(File.read(@config[:users_file]))
      
      @log.debug "old hash: #{old_hash}"
      @log.debug "new hash: #{@new_hash}"
      
      old_hash != @new_hash
    end

    def check_for_notify_email(user)
      
      saved_email = "#{@config[:usersync][:mailq]}/#{user.name}.txt"
      
      if !File.exist? saved_email
        @log.info "#{user.name} does not have a saved email"
        @log.debug "#{saved_email} is missing, admin didn't check notify?"
        return false
      end

      @log.debug "found saved email at #{saved_email}"

      j = JSON.load( File.read( saved_email ) )

      secret = extract_password j["body"]
      user.set_linux_password secret
      @log.info "Set linux password for #{user.name}"
      
      notify_user j
      @log.info "#{user.name} was sent their details via email"

      # Delete the file now that we are done with it
      File.unlink saved_email
    end

    def extract_password(body)
      m = body.match(/Password : (.*)\n\n--/)
      
      if m.nil?
        raise PasswordMatchError, "Couldn't get password from saved email"
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