module Braincase
  class DropboxQueueManager

    def initialize(queues, users, log, dropbox)
      @queues = queues
      @users = users
      @log = log
      @dropbox = dropbox
    end

    def enable

      # loop through each line in the file
      File.read(@queues[:enable]).each do |name|

        begin

          next if name.empty?
          next if name.include? "emailed" # user already been emailed

          user = @user.build @users.match(/^#{name}:.*$/)[0] # get the user from the user list

          next if !user.in_linux # don't try to setup dropbox if no linux user
          
          # user enabled? remove from queue
          if @dropbox.enabled_for user
            add_to_queue :enabled
            remove_from_queue :enable
            next
          end

          setup_dropbox user
        rescue RuntimeError => e

          puts e.message
          @log.error e.message
        end
      end
    end

    def add_to_queue(queue, user)
      case queue
      when :enabled
        add_to_enabled user.name
        @log.info "#{user.name} added to enabled queue"
      when :emailed
        set_as_emailed user.name
        @log.info "#{user.name} added to emailed queue"
      end
    end

    def remove_from_queue(queue, user)
      case queue
      when :enable
        remove_from_enable_queue user.name
        @log.info "#{user.name} removed from enable queue"
      end
    end

    private

    def setup_dropbox(user)

      output=`su #{user.name} -c "braincase-setup-dropbox -e #{user.email}"`

      if $?.exitstatus != 0
        output.split("\n").each do {|line| @log.error line }
        raise RuntimeError, "Running braincase-setup-dropbox for #{user.name} failed with error #{$?.exitstatus}"
      end

      add_to_queue :emailed, user
    end

    def remove_from_enable_queue(name)
      
      text = File.read(@queues[:enable])
      text.gsub!(/^#{name}$/, "") # remove the user from the queue
      text.gsub!(/^$/, "") # clear blank lines
      puts "TEXT: #{text}"
      
      File.open(@queues[:enable], 'w') do |f|
        f.puts text
      end
    end

    def set_as_emailed(name)
      
      text = File.read(@queues[:enable])
      text.gsub!(/^#{name}$/, "#{name} emailed")

      File.open(@queues[:enable], "w") do |f|
        f.puts text
      end
    end

    def add_to_enabled(name)
      
      # drop out if user already enabled
      return if File.read(@queues[:enabled]).include? "#{name}\n"

      # otherwise add the user to the file
      File.open(@queues[:enabled], "a") do |f|
        f.puts name
      end
    end
  end
end