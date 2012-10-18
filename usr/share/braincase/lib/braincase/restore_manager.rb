module Braincase
  class RestoreManager

  	def initialize(log,config)
  	  @config=config
  	  @log=log
  	end

  	def restore(opts={})
  	  
      check_and_build_arguments opts
      
      @log.info "Running restore with options #{opts.inspect}"
      @log.debug "Need to restore #{@what} data"

  	  case @what
  	  when "dokuwiki"
        @log.debug "Restoring dokuwiki data"
        to = "#{@user.dirs[:doku]}/data.#{@timestamp}"
        restore_from_home ".dokuwiki/data.current", to, 4

  	  else
  	  	raise ArgumentError, "Unsupported restore type #{@what}"

  	  end
  	end

    def check_and_build_arguments(opts={})
      
      raise ArgumentError, "Missing arguments" if
        opts[:who].nil? or 
        opts[:when].nil? or 
        opts[:from].nil? or
        opts[:what].nil?

      @user = User.load opts[:who]

      raise UserMissingError if !@user.in_linux?
      raise NoBraincaseError if !@user.has_braincase?

      @timestamp = opts[:when]

      raise ArgumentError, "Incorrect timestamp: #{@timestamp}" if
        !Braincase.validate_timestamp @timestamp
        
      @source = opts[:from]

      raise ArgumentError, "Invalid source: #{@source}" if
        !["dropbox", "local"].include? @source

      @what = opts[:what]

      raise ArgumentError, "Invalid what: #{@what}" if
        !["all", "dokuwiki", "repo"].include? @what
    end

    # Restores /home/user/{file} from the archive
    # file as "" means the whole directory is extracted
    #tar -xf daily_backup.tar daily_backup/archives/home.tar.gz --strip-components=2 --to-stdout | tar -zx /home/test/.dokuwiki --strip-components=2
    def restore_from_home(file, to, strip_folders=2)

      base = get_base

      # Determine the file paths we need to play with
      backup_tar = "#{base}/#{@timestamp}/daily_backup.tar"
      gzipped_home = "daily_backup/archives/home.tar.gz"
      restore_file = "/home/test/#{file}"

      @log.debug "Restoring from tar: #{backup_tar}"
      @log.debug "Restoring from archive in tar: #{gzipped_home}"
      @log.debug "Restoring from archive path: #{restore_file}"
      @log.debug "Restoring to: #{to}"

      raise RestoreError, "Could not find backup tar" if !File.exist? backup_tar

      # Create the directory and check it is there
      @user.run "mkdir #{to}" if !File.directory? to
      raise RestoreError, "Unable to create the directory #{to}" if !File.directory? to

      output=`tar -xf #{backup_tar} #{gzipped_home} --strip-components=2 --to-stdout | tar -C #{to} -zx #{restore_file} --strip-components=#{strip_folders} 2>&1`

      raise RestoreError, "Unable to restore the backup: #{output}" if $?.exitstatus != 0
      # TODO: more postcons
    end

    # Determine the base directory from the source
    def get_base
      case @source
      when "dropbox"
        base = "#{@user.dirs[:dropbox]}/Braincase/Memories"
      when "local"
        base = "#{@user.dirs[:backups]}/daily_backup"
      else
        raise RestoreError, "Could not determine base directory: invalid source #{@source}"
      end
      base
    end
  end
end