# as per http://stackoverflow.com/questions/5200842/where-to-define-custom-error-types-in-ruby-and-or-rails
module Braincase

  class UserMissingError < StandardError; end
  class NoBraincaseError < StandardError; end
  class NoBackupEnvError < StandardError; end
  class BackupExportError < StandardError; end
  class RestrictedUserError < StandardError; end
  class RestoreError < StandardError; end
  class UserCreationError < StandardError; end

end