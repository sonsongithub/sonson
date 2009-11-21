require 'fileutils'
raise unless ARGV.length == 3
template_file_name = ARGV.shift
lang_abbrev = ARGV.shift
module_name   = ARGV.shift

template = File.read(template_file_name)
template.gsub!(/LANGNAME/, lang_abbrev.upcase)
template.gsub!(/langname/, lang_abbrev.downcase)
template.gsub!(/LangName/, module_name)

c_file_name = lang_abbrev + ".c"
FileUtils.rm_f(c_file_name)
File.open(c_file_name, "w") {|f|
  f.printf("/* %s generated automatically from %s */\n",
           c_file_name, template_file_name)
  f.print template
}
File.chmod(0444, c_file_name)
