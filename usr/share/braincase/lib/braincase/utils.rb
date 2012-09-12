require 'yaml'

module Braincase

  CONFIG_FILE = "/etc/braincase/config"

  def Braincase.config(section='')
    
    raw = File.read( CONFIG_FILE )
    yml = YAML.load( raw )

    # Return the section or the whole thing
    if !section.empty?
      yml[section]
    else
  	  yml
  	end
  end

  def Braincase.is_root?
    `echo $USER`.chomp == "root"
  end
end