# encoding: utf-8

$LOAD_PATH.unshift(File.dirname("/usr/share/braincase/lib/braincase"))

require 'yaml'
require 'braincase/utils'
require 'braincase/user'

$conf = Braincase.config
$user = Braincase.current_user
$date = Time.new.strftime("%Y.%m.%d.%H.%M.%S") # TODO: add this format string to config

##
# Backup Generated: daily_backup
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t daily_backup [-c <path_to_configuration_file>]
#
Backup::Model.new(:daily_backup, "Daily Braincase backup for #{$user.name}") do
  ##
  # Split [Splitter]
  #
  # Split the backup file in to chunks of 250 megabytes
  # if the backup file size exceeds 250 megabytes
  #
  split_into_chunks_of 250
  ##
  # Archive [Archive]
  #
  # Adding a file:
  #
  #  archive.add "/path/to/a/file.rb"
  #
  # Adding an directory (including sub-directories):
  #
  #  archive.add "/path/to/a/directory/"
  #
  # Excluding a file:
  #
  #  archive.exclude "/path/to/an/excluded_file.rb"
  #
  # Excluding a directory (including sub-directories):
  #
  #  archive.exclude "/path/to/an/excluded_directory/
  #
  archive :home do |a|
    a.add "#{$user.repo}.mirror"
    a.add $user.dirs[:doku_current]
    a.add $user.dirs[:braincase]
    a.add $user.dirs[:logs]
  end

  ##
  # Local (Copy) [Storage]
  #
  store_with Local do |local|
    local.path       = $user.dirs[:backups]
    local.keep       = 14
  end

  ##
  # Gzip [Compressor]
  #
  compress_with Gzip

  ##
  # Mail [Notifier]
  #
  # The default delivery method for Mail Notifiers is 'SMTP'.
  # See the Wiki for other delivery options.
  # https://github.com/meskyanichi/backup/wiki/Notifiers
  #
  notify_by Mail do |mail|
    mail.on_success           = true
    mail.on_warning           = true
    mail.on_failure           = true

    mail.from                 = $conf[:email][:from]
    mail.to                   = $user.email
    mail.address              = "localhost"
    mail.port                 = 25
    mail.domain               = $conf[:email][:domain]
    #mail.user_name            = user
    #mail.password             = password
    #mail.authentication       = plaintext
    #mail.enable_starttls_auto = true
  end

end
