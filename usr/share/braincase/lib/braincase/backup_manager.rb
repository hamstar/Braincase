require 'braincase/exceptions'

module Braincase
  class BackupManager

    def initialize(log)
      @log=log
    end

    def perform_backups

      # Run through all the users in dokuwiki
      User.all.each do |user|

        @user=user
        
        begin
          
          userlog = Logger.new @user.logs[:backup]
          userlog.level = Logger::INFO

          # Run some checks first
          raise UserMissingError if !@user.in_linux?
          raise NoBraincaseError if !@user.has_braincase?
          raise NoBackupEnvError if !@user.can_backup?
          
          timestamp = @user.perform_backup
          
          # Do the exporting
          export_to :dropbox, timestamp if @user.has_dropbox?

        rescue UserMissingError
          @log.error "#{@user.name} does not exist in linux"

        rescue NoBraincaseError
          
          @log.error "#{@user.name} is not a braincase user"
        rescue NoBackupEnvError

          userlog.error "#{@user.name} does not have a properly setup backup environment"
        rescue BackupExportError

          userlog.error "Failed to export to dropbox"
        rescue => e

          @log.error e.message
        end

        userlog = nil
        @user = nil
      end
    end

    def export_to(target, timestamp)

      case target
      when :dropbox # export the backup to dropbox
        backup = "#{@user.dirs[:backups]}/#{timestamp}"
        dropbox_backup = "#{@user.dirs[:dropbox]}/Braincase/Memories"
        @user.cp backup, dropbox_backup, "-R" # run as the user so the permissions are set
        raise BackupExportError if $?.exitstatus != 0
      end
    end
  end
end