module Braincase
  class UserUtils
    # Convenience methods - adds readability to the code
    def ln(source, link)
      run "ln -s #{source} #{link}"
    end

    def ln!(source, link)
      `ln -s #{source} #{link}`
    end
    
    def cp(from, to, opts="")
      run "cp #{opts} #{from} #{to}"
    end

    def cp_contrib(file, to)
      from = "/usr/share/braincase/contrib/"+file
      run "cp #{from} #{to}"
    end

    def touch(file) 
      run "touch #{file}"
    end
  end
end