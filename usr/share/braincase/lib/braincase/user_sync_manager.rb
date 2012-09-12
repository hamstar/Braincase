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

      # Get all the lines from the userfile
      lines=`cat #{userfile} | grep -vP '^#|^\s'`.split("\n")

      @log.info "#{lines.count} users in the userfile"

      # Run through each user and create ones that are missing
      lines.each do |line|
        name = line.split(":")[0]
        user = @user.build line
        user.create
        @log.info "Created #{user} in system"
      end
    end

    def users_changed?

      old_hash = File.read( @config[:usersync][:users_hash] )
      new_hash = @md5.hexdigest(File.read(@config[:users_file]))
      
      if old_hash != new_hash
        return false
      end

      File.open(@config[:usersync][:users_hash], 'w'){|f| f.write(new_hash)} # changed write new hash to disk
        @log.info "The user file has changed, doing a sync"
    end
  end
end