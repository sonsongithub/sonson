#
# langscan.rb - an interface module of LangScan
#
# Copyright (C) 2004-2005 Satoru Takabayashi <satoru@namazu.org> 
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

module LangScan
  LangScanRegistry = {}

  module_function
  def load_plugins(plugin_path)
    $LOAD_PATH.each {|path|
      candidate_path = File.join(path, plugin_path)
      next unless File.directory?(candidate_path)
      Dir.entries(candidate_path).each {|entry|
        if File.extname(entry) == ".rb" and not /^_/.match(entry)
          begin
            require(File.join(plugin_path, entry))
          rescue LoadError => e
            # ignore load errors
          end
        end
      }
    }
  end

  def load
    load_plugins("langscan")
  end

  def validate_module(mod)
    common_methods = [:name, :abbrev, :scan]
    safe_characters = "[a-z]+"
    common_methods.each {|method|
      raise "#{mod.to_s} lacks #{method}" unless mod.respond_to?(method)
    }
    unless /^#{safe_characters}$/.match(mod.abbrev)
      raise "#{mod.to_s} invalid abbreviation: #{mod.abbrev}"
    end
  end

  def register(mod)
    validate_module(mod)
    mod.extnames.each {|extname|
      if LangScanRegistry.include?(extname)
        mod = LangScanRegistry[extname]
        raise "#{extname} is already used by #{mod.abbrev}"
      end
      LangScanRegistry[extname] = mod
    }
  end

  def modules
    LangScanRegistry.values.uniq
  end

  def choose_by_shebang(content)
    first_line = ""
    content.each_line {|line|
      first_line = line
      break
    }
    LangScanRegistry.each_value {|scanner|
      regexp = /^#!.*\b#{scanner.abbrev}/i
      return scanner if regexp.match(first_line)
    }
    return nil
  end
  
  def choose_by_emacs_mode(content)
    chunk = content[0, 512] # FIXME: magic number
    LangScanRegistry.each_value {|scanner|
      mode = Regexp.quote(scanner.name.downcase.gsub(/\s+/, "-"))
      if scanner.name.include?("/") # "C/C++" etc.
        mode = "(" + mode + "|"
        mode << scanner.name.split("/").map {|part| Regexp.quote(part) }.join("|")
        mode << ")"
      end
      regexp = /-\*-\s+mode:\s+#{mode}\s+-\*-/i
      return scanner if regexp.match(chunk)
    }
    return nil
  end

  def choose_by_content(content)
    return (choose_by_shebang(content) or choose_by_emacs_mode(content))
  end

  def choose(file_name, content = nil)
    extname = File.extname(file_name)
    scanner = LangScanRegistry[extname]
    scanner = choose_by_content(content) if scanner.nil? and content
    return scanner
  end

  def support?(file_name)
    extname = File.extname(file_name)
    LangScanRegistry.include?(extname)
  end
end

LangScan.load
