require 'braincase/utils'
require 'braincase/exceptions'
require 'json'
require 'braincase/user_utils'

module Braincase
  class User < UserUtils

    attr_reader :name, :home, :repo, :logs, :dirs, :memories
    attr_accessor :email, :full_name, :groups

    def initialize(name)
      
      if name == "root" or name == "admin"
        raise RestrictedUserError
      end

      @name=name
      @home="/home/#{name}"
      @repo="#{home}/#{name}.git"
      
      @dirs = {
        home: @home,
        repo: @repo,
        doku: "#{@home}/.dokuwiki",                      # change the one down there too
        braincase: "#{@home}/.braincase",
        dropbox: "#{@home}/Dropbox",
        backups: "#{@home}/backups",
        restores: "#{@home}/restores",
        logs: "#{@home}/logs",
        doku_current: "#{@home}/.dokuwiki/data.current"  # change the one up there too ^^^
      }
      
      @logs = {
        backup: "#{@dirs[:logs]}/backup.log",
        dropbox: "#{@dirs[:logs]}/dropbox_setup.log",
        restore: "#{@dirs[:logs]}/restore.log",
      }

      if File.exist? "#{@home}/memories.list"
        @memories = JSON.load( File.read( "#{@home}/memories.list") )
      else
        @memories = []
      end
    end

    # Build a user from a line in the user_file
    def self.build(line)
      @line = line
      vars = line.split(":")
      
      u = self.new vars[0]
      u.email = vars[3]
      u.full_name = vars[2]
      u.groups = vars[4]

      u
    end

    # Loads a user from the config file in their home directory
    def self.load(name)

      u = self.new name
      raise UserMissingError if !u.in_linux?
      raise NoBraincaseError if !u.has_braincase?
      raise RuntimeError, "User not saved" if !File.exist? "#{u.dirs[:braincase]}/config"

      self.build File.read("#{u.dirs[:braincase]}/config").chomp
    end

    def self.all

      users = Array.new
      File.open( Braincase.config[:users_file], "r" ).each do |line|
        begin
          users << self.build(line)
        rescue RestrictedUserError
          # silent ignore
        end
      end

      users
    end

    # This only allows maximum 8 letters
    def set_linux_password(secret)
      
      if !Braincase.is_root?
        raise PasswordSetError, "Only root is allowed to set passwords"
      end

      if !in_linux?
        raise PasswordSetError, "User #{@name} does not exist in linux"
      end

      pass = `openssl passwd #{secret}`.chomp
      output = `usermod -p #{pass} #{@name}`  # set the password

      if $?.exitstatus != 0
        raise PasswordSetError, "Unable to set password for user (#{$?.exitstatus}): #{output}"
      end

      true
    end

    # Performs a backup for the user
    # Returns the timestamp in format YYYY.mm.dd.hh.mm.ss
    def perform_backup
      
      add_memories_to_dropbox! if has_dropbox?

      # Clone the repo incase something is writing to it while we are backing up
      run "cd #{@home} && git clone --bare #{@repo} #{@repo}.mirror"
      output=run "backup perform --trigger=daily_backup --log-path #{@dirs[:logs ]}"
      run "cd #{@home} && rm -fr #{@repo}.mirror"
        
      get_timestamp(output)
    end

    # Gets the timestamp from the backup script output
    # in format YYYY.mm.dd.hh.mm.ss
    def get_timestamp(output)
      output.split("\n").first.match(/^\[([^\]]*)\]/)[1].gsub(/\/| |:/,'.')
    end

    def can_backup?

      return false if !File.exist? "#{@home}/Backup/config.rb"
      return false if !File.exist? "#{@home}/Backup/models/daily_backup.rb"

      true
    end

    def add_memories_to_dropbox!
      run "mkdir -p #{@dirs[:dropbox]}/Braincase/Memories" if
        !File.directory? "#{@dirs[:dropbox]}/Braincase/Memories"
    end

    def save_config

      return false if !has_braincase?
      @line = "#{@name}::#{@full_name}:#{@email}:#{@groups}" if @line.nil?

      File.open("#{@dirs[:braincase]}/config","w") {|f| f.write @line}
      own_file! "#{@dirs[:braincase]}/config"
    end

    def in_linux?
      File.directory? @home
    end

    def self.in_linux(name)
      File.directory? self.new(name).home
    end

    def has_dropbox?
      File.directory? @dirs[:dropbox]
    end

    def in_dokuwiki?
      begin
        return File.read(Braincase.config[:users_file]).match(/^#{user}:/)
      rescue
        return false
      end
    end

    def has_repo?
      File.directory? @repo
    end

    def has_braincase?
      File.directory? @dirs[:braincase]
    end

    def has_dokuwiki?
      File.directory? @dirs[:doku]
    end

    def own_file!(file)
      `chown #{@name}:#{@name} #{file}`
    end

    def run(cmd)
      output=`su #{@name} -c "#{cmd}"`
    end
  end
end