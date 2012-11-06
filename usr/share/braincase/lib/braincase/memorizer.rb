require 'json'
require 'find'
require 'braincase/exceptions'
require 'braincase/user'

module Braincase
  class Memorizer

  	def initialize(log)
      @log=log

      # This is the timestamp pattern YYYY.mm.dd.hh.mm.ss
      # will match /home/user/backups/2012.10.10.23.42.11 and extract the timestamp
      @pattern = /.*\/(\d{4}\.\d{2}\.\d{2}\.\d{2}\.\d{2}\.\d{2})$/
  	end

    def memorize

      User.all.each do |user|
  
        @user=user
        @memories = []

        @log.info "Searching for memories belonging to #{@user.name}"

        begin

          # Run some checks first
          raise UserMissingError if !@user.in_linux?
          raise NoBraincaseError if !@user.has_braincase?
  
      	  look_in :local
          look_in :dropbox if @user.has_dropbox?
  
          save

        rescue UserMissingError
          @log.debug "#{@user.name} is not in linux"

        rescue NoBraincaseError
          @log.debug "#{@user.name} is not a braincase user"

        rescue ArgumentError => e
          @log.debug e.message

        end

        @user = nil
      end
    end

    private

    def look_in(target)

      case target
      when :dropbox
      	find_in_dropbox
      when :local
      	find_in_local
      else
        raise ArgumentError, "Don't know how to look in #{target}"
      end

    end

    def find_in_dropbox

      Find.find("#{@user.dirs[:dropbox]}/Braincase/Memories").each do |dir|      	
      	next if !File.directory? dir
        next if ( match = dir.match @pattern ).nil?
      	timestamp = match[1]
      	@memories << { source: :dropbox, date: timestamp }
      end
    end

    def find_in_local

      Find.find("#{@user.dirs[:backups]}").each do |dir|
        next if !File.directory? dir
      	next if ( match = dir.match @pattern ).nil?
      	timestamp = match[1]
      	@memories << { source: :local, date: timestamp }
      end
    end

    def save
      File.open("#{@user.home}/memories.list", "w") {|f|
        f.puts @memories.to_json
      }

      @log.info "Saved #{@memories.count} memories for #{@user.name}"
    end
  end
end