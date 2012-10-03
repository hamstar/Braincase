require 'braincase/utils'
require 'braincase/user_utils'

module Braincase
  class User < UserUtils

    attr_reader :name, :home, :repo, :logs, :dirs
    attr_accessor :email, :full_name, :groups

    def initialize(name)
      
      if name == "root"
        raise RuntimeError, "Cannot use root user"
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
        logs: "#{@home}/logs",
        doku_current: "#{@home}/.dokuwiki/data.current"  # change the one up there too ^^^
      }
      
      @logs = {
        backup: "#{@dirs[:logs]}/backup.log",
        dropbox: "#{@dirs[:logs]}/dropbox_setup.log"
      }
    end

    def self.all

      users = []
      File.open( Braincase.config[:users_file], "r" ).each do |line|
        users[] = self.build line
      end

      users
    end

    # Build a user a line in the user_file
    def self.build(line)
      
      vars = line.split(":")
      
      u = self.new vars[0]
      u.email = vars[3]
      u.full_name = vars[2]
      u.groups = vars[4]

      u
    end

    def set_linux_password(secret)
      
      if !Braincase.is_root?
        raise RuntimeError, "Only root is allowed to set passwords"
      end

      if !in_linux?
        raise RuntimeError, "User #{@name} does not exist in linux"
      end

      pass = `openssl passwd #{secret}`.chomp
      output = `usermod -p #{pass} #{@name}`  # set the password

      if $?.exitstatus != 0
        raise RuntimeError, "Unable to set password for user (#{$?.exitstatus}): #{output}"
      end

      true
    end

    def perform_backup

      # Set what we can export backups to
      export_to :dropbox
      
      run "backup perform --trigger=daily_backup --log-path #{@logs[:backup]}"
    end

    # Preps files/folders/links to ensure that a backup can be exported
    # for whatever target is given
    def export_to(target)
      case target
      when :dropbox
        link_dropbox_backups
      end
    end

    # Makes the link between backups and the Dropbox dir
    def link_dropbox_backups
      if has_dropbox? and !File.exist? "#{@dirs[:dropbox]}/Braincase/Memories"
        run "mkdir #{@dirs[:dropbox]}/Braincase"
        ln @dirs[:backups], "#{@dirs[:dropbox]}/Braincase/Memories"
      end
    end

    def save_config

      if !has_braincase?
        return false
      end

      c = { 
        [@name] => {
          full_name: @full_name,
          email: @email,
          groups: @groups,
          dirs: @dirs,
          logs: @logs
        }
      }

      File.open("#{@dirs[:braincase]}/config","w") {|f| f.write c.to_yaml}
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