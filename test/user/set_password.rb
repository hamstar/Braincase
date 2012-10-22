#!/usr/bin/ruby

$LOAD_PATH.unshift(File.dirname("/usr/share/braincase/lib/braincase"))

require 'braincase/user'

u = Braincase::User.new "test"

puts "This file tests that the user model sets the password correctly for the test user."
puts ""
print "Set a password for user test here: "
pass = STDIN.gets
u.set_linux_password pass.chomp

print "Now test that "
system 'su test -c "su test -c\"echo It worked\"" 2>&1 > /dev/null'

abort "Test failed" if $?.exitstatus != 0
puts "Test passed" if $?.exitstatus == 0

