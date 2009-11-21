require 'fileutils'
raise unless ARGV.length == 4
template_file_name = ARGV.shift
token_list_file_name = ARGV.shift
lang_abbrev = ARGV.shift
module_name = ARGV.shift

token_list = File.open(token_list_file_name).readlines.map {|line| line.chomp }

lines = ["#define LANGSCAN_LANGNAME_TOKEN_LIST"]
token_list.each {|token|
  lines.push("     LANGSCAN_LANGNAME_TOKEN(#{token})")
}
macro = lines.join(" \\\n")

template = File.read(template_file_name)
template.gsub!(/@LANGSCAN_LANGNAME_TOKEN_LIST@/, macro)
template.gsub!(/LANGNAME/, lang_abbrev.upcase)
template.gsub!(/langname/, lang_abbrev.downcase)
template.gsub!(/LangName/, module_name)

h_file_name = lang_abbrev + ".h"
FileUtils.rm_rf(h_file_name)
File.open(h_file_name, "w") {|f|
  f.printf("/* %s generated automatically from %s */\n",
           h_file_name, template_file_name)
  f.print template
}
File.chmod(0444, h_file_name)
