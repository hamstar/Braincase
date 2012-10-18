require 'braincase/user_utils'

module Braincase
  class UserCreator < UserUtils

  	def initialize(log, config)
  	  
  	  @log=log
  	  @config=config
  	  @default_doku_folders = "pages meta attic"
  	end

  	def create(user)
	  
	  @user=user
      @log.debug "Creating a new Braincase user #{@user.name}"

      begin

      	# These are in a specific order
        add_to_linux!
        setup_bare_repo
        add_userdir
        add_braincase
        add_backups
        setup_logs
        setup_wiki!
        setup_local_repo

      rescue => e
        @log.error "Failed to create user #{@user.name}"
        Braincase.log_lines @log, e.message
        Braincase.log_lines @log, e.backtrace, :debug
      end
  	end
	
    def add_to_linux!
      if !@user.in_linux?
        output = `/usr/sbin/useradd -s /bin/bash -md #{@user.home} #{@user.name} 2>&1`

        # Die unless the user was created or exists
        if $?.exitstatus != 0 and $?.exitstatus != 9
          raise RuntimeError, "Could not add user to linux (#{$?.exitstatus})\n#{output}"
        end
      end
    end

    def setup_logs
      run "mkdir #{@user.dirs[:logs]}"
      touch @user.logs[:backup]
      touch @user.logs[:dropbox]
    end

    def setup_wiki!

      create_wiki_folders!
      create_wiki_files!
      create_wiki_symlinks
    end

    def create_wiki_folders!
      run "mkdir -p #{@user.dirs[:doku_current]}"
      run "cd #{@user.dirs[:doku_current]} && mkdir -p #{@default_doku_folders}"
      run "mkdir #{@user.dirs[:doku_current]}/pages/logs"
    end

    def create_wiki_files!

      # Add default files
      cp_contrib "user_start.txt", "#{@user.dirs[:doku_current]}/pages/start.txt"
      cp_contrib "logs_start.txt", "#{@user.dirs[:doku_current]}/pages/logs/start.txt"

      # Modify files if needed
      File.open("#{@user.dirs[:doku_current]}/pages/logs/start.txt", "w+") {|f|
        text = f.read.gsub("$USER$", @user.name)
        f.write text
      }
    end

    def create_wiki_symlinks

      @default_doku_folders.split(" ").each do |folder|
        target = "#{@user.dirs[:doku_current]}/#{folder}"
        link = "#{@config[:data_dir]}/#{folder}/#{@user.name}"
        ln! target, link
      end

      link_logs_in_wiki
    end

    def link_logs_in_wiki
  
  	  #TODO: use glob
      run("ls #{@user.dirs[:logs]} -1").split("\n").each do |log|
        fn = log.gsub("log", "txt")
        ln log, "#{@user.dirs[:doku_current]}/pages/logs/#{fn}"
      end
    end

    def setup_bare_repo
      if !@user.has_repo?
        run "mkdir #{@user.repo}"
        run "cd #{@user.repo} && git init --bare"
        add_hook_to_repo!
      end
    end

    def setup_local_repo
      if !File.directory? "#{@user.home}/.git"
        run "cd #{@user.home} && git init"
        run "cd #{@user.home} && git remote add origin #{@user.repo}"
        run "cd #{@user.home} && git config --global user.email \"#{@user.email}\""
        run "cd #{@user.home} && git config --global user.name \"#{@user.full_name}\""
        add_ignore_file!
        do_first_commit!
      end
    end

    def do_first_commit!
      if File.directory? "#{@user.home}/.git"
        run "cd #{@user.home} && git add . && git commit -m 'first commit'"
        run "cd #{@user.home} && git push origin master 2>&1 > /dev/null"
      else
        @log.error "Couldn't do the first commit as the repo wasn't created!"
      end
    end

    def add_ignore_file!
      cp_contrib "gitignore.example", "#{@user.home}/.gitignore"
    end

    def add_hook_to_repo!
      cp_contrib "post-receive.example", "#{@user.repo}/hooks/post-receive"
      `chmod u+x #{@user.repo}/hooks/post-receive`
    end

    def add_userdir
      if !File.directory? "#{@user.home}/public_html"
        run "mkdir #{@user.home}/public_html"
        run "touch #{@user.home}/public_html/.gitkeep"
      end
    end

    def add_braincase
      if !@user.has_braincase?
        run "mkdir #{@user.dirs[:braincase]}"
        @user.save_config
      end
    end

    def add_backups
      if !File.directory? @user.dirs[:backups]
        run "mkdir -p #{@user.dirs[:backups]}"
        run "mkdir -p #{@user.home}/Backup/models"
        cp_contrib "daily_backup.rb", "#{@user.home}/Backup/models"
        cp_contrib "backup_config.rb", "#{@user.home}/Backup/config.rb"
        run "echo \[\] > #{@user.home}/memories.list"
      end
    end

    def run(cmd)
      output = @user.run "#{cmd} 2>&1"
      @log.debug "run `#{cmd}` as #{@user.name} finished with status #{$?.exitstatus}"

      if $?.exitstatus != 0
      	Braincase.log_lines @log, output
      end
      output
    end
  end
end