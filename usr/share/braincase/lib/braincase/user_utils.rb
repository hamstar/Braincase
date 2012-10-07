module Braincase
  class UserUtils
    # Convenience methods - adds readability to the code
    def ln(source, link)
      run "ln -s #{source} #{link}"
    end

    def ln!(source, link)
      `ln -s #{source} #{link}`
    end

    # If contrib is true then the root directory of from
    # is treated as the contrib folder (usually /usr/share/braincase/contrib/)
    def cp(from, to, contrib=true)
      if contrib
        from = "/usr/share/braincase/contrib/"+from
      end

      run "cp #{from} #{to}"
    end

    def touch(file) 
      run "touch #{file}"
    end
  end
end