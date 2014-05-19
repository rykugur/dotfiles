#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'
require 'ostruct'
require 'pp'

require './dotfile_lib'

base_path = DotfileLib::getBasePathNoFlag

# TODO: This is pretty stupid... it assumes one or the other...
if base_path.include? "work"
  file_paths = DotfileLib::work_file_paths
else
  file_paths = DotfileLib::personal_file_paths
end

home = Dir.home
file_paths.each { |dotfile|
  file = "#{home}/#{dotfile.split(",").last}"

  # delete the file
  FileUtils.rm_f(file)
}
