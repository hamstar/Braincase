module Braincase
  class RestoreManager
    
  	def initialize(log,config)
  	  @config=config
  	  @log=log
  	end

  	def restore(what,user,timestamp)
  	  
  	  @user = user
  	  @timestamp = timestamp

  	  case what
  	  when :dokuwiki
  	  	dokuwiki
  	  else
  	  	abort "Unsupported restore type #{what}"
  	  end
  	end

  	def dokuwiki

      link_in_dokuwiki get_location
  	end

  	def get_location

  	  # Is this memory already in short term memory?
      location = "#{user.dirs[:doku]}/data.#{timestamp}"
      return location if File.directory? location
      
      # Or do we have to extract it from our long term memory?
      return extract_memory find_memory
  	end

    def find_memory
      
      # Is it in the list of memories?
      @user.memories.each do |memory|
        return memory if memory[:date] != @timestamp # found it!
	  end

	  raise RuntimeError, "Cannot find memory for the timestamp #{@timestamp}"
	end

    def extract_memory(memory)
      
      case memory[:source]
      when "local"
        backup_path = @user.dirs[:backup]
      when "Dropbox"
      	backup_path = @user.dirs[:dropbox]
      else
      	raise RuntimeError, "Unsupported backup source #{memory[:source]}"
      end

      backup_tar = "#{backup_path}/#{@timestamp}/daily_backup.tar"
      tmp_path = "#{@user.dirs[:tmp]}/#{@timestamp}" 
      tmp_dokuwiki_tar = "#{tmp_path}/dokuwiki.tar.gz"
      memory_location = "#{@user.dirs[:doku]}/data.#{@timestamp}"

      raise RuntimeError, "Cannot find the backup specified (#{backup_tar})" if !File.exist? backup_tar 
  
      FileUtils::rm_rf tmp_path if File.directory? tmp_path
      FileUtils::mkpath tmp_path
      FileUtils::mkpath memory_location
      `tar -xf #{backup_tar} -C #{tmp_path}`
      `tar -xzf #{tmp_dokuwiki_tar} -C #{memory_location}`

      # Make sure our memory is not corrupt
      raise RuntimeError, "Could not extract memory" if 
        !File.directory? "#{memory_location}/pages" or
        !File.directory? "#{memory_location}/meta" or
        !File.directory? "#{memory_location}/attic"

      memory_location
    end

    def link_in_dokuwiki(location)
      %w[pages meta attic].split(" ").each do |folder|
      	link = "#{@config[:data_dir]}/#{folder}/#{@user.name}"
      	target = "#{location}/#{folder}"
        File.unlink link
        File.symlink target, link
      end
    end
  end
end