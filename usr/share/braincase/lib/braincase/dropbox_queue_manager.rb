module Braincase
  class DropboxQueueManager

    def initialize(queues, passwd, log)
      @queues = queues
      @passwd = passwd
      @log = log
    end

    def enable

      # loop through each line in the file
      get_lines_from(@queues[:enable]).each do |line|
        
        user = make_user line

        begin

          next if dropbox_enabled_for user[:name]
          next if user[:emailed]

          user_exists_in_linux user[:name]
          setup_dropbox_and_email user[:name] # otherwise set them up
        rescue "Error" => e

          puts e.message
          @log.error e.message
        end
      end
    end

    private

    def get_lines_from(queue)

      f = File.open(queue, 'r') # open the queue
      lines = f.read.split("\n")
      f.close

      @log.info "#{lines.count} users in the queue"

      lines
    end

    def user_exists_in_linux(user)

      if `user-exists #{user}; echo $?`.chomp != "0" # check the user actually exists
        raise "Error", "#{user} has not been created in linux, skipping..."
      end

      @log.info "#{user} exists in linux"
    end

    def dropbox_enabled_for(user)

      if File.directory? "/home/#{user}/Dropbox" # is the Dropbox folder present?
        
        @log.info "#{user} already setup for Dropbox"
        set_dropbox_status user, "enabled"
        return true
      end

      false
    end

    def make_user(line)
      user = {
        name: line,
        emailed: false
      }

      if line.include? "emailed"
        user[:name] = line.split(" ")[0]
        user[:emailed] = true
      end

      user
    end

    def setup_dropbox_and_email(user)

      if email = @passwd.match(/^#{user}:.*/)[0].split(":")[3]
        
        system "su #{user} -c \"braincase-setup-dropbox -e #{email}\""
        set_dropbox_status user, "queued"
        @log.info "#{user} setup for Dropbox access"
      else

        raise "error", "Email could not be found for #{user}"
      end
    end

    def remove_from_enable_queue(user)
      
      text = File.read(@queues[:enable])
      text.gsub!(/^#{user}$/, "") # remove the user from the queue
      text.gsub!(/^$/, "") # clear blank lines
      puts "TEXT: #{text}"
      
      File.open(@queues[:enable], 'w') do |f|
        f.write text
      end
    end

    def set_dropbox_status(user, status)

      case status
        when "queued"
          set_user_as_emailed user
        when "enabled"
          remove_from_enable_queue user
          add_user_to_enabled_users user
        else
      end
    end

    def set_user_as_emailed(user)
      
      text = File.read(@queues[:enable])
      text.gsub!(/^#{user}$/, "#{user} emailed")

      File.open(@queues[:enable], "w") do |f|
        f.puts text
      end

      @log.info "#{user} was emailed"
    end

    def add_user_to_enabled_users(user)
      
      # drop out if user already enabled
      if File.read(@queues[:enabled]).include? "#{user}\n"
        return;
      end

      # otherwise add the user to the file
      File.open(@queues[:enabled], "a") do |f|
        f.puts user
      end
    end

  end
end