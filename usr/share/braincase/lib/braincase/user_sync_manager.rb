module Braincase
  class UserSyncManager

    def initialize( config, log, user, md5 )

      @config=config
      @log=log
      @user=user
      @md5=md5
    end

    def sync

      return false if !users_changed?

      @log.info "The user file has changed, doing a sync"

      # Run through each user and create ones that are missing
      File.read(@config[:users_file]).each do |line|
        begin
          user = @user.build line
          next if user.has_braincase
          user.create
          @log.info "Created #{user.name} in system"
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
      
      old_hash != @new_hash
    end
  end
end