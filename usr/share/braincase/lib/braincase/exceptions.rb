# as per http://stackoverflow.com/questions/5200842/where-to-define-custom-error-types-in-ruby-and-or-rails
module Braincase

  class RestrictedUserError < StandardError; end

end