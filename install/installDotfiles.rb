#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'
require 'ostruct'
require 'pp'

require './dotfile_lib'

options = DotfileLib::parse
pp "options: #{options}" if options.verbose

DotfileLib::validateOpts(options)

if options.personal
  file_paths = DotfileLib::personal_file_paths
elsif options.work
  file_paths = DotfileLib::work_file_paths
end

# TODO: this is really naive
base_path = DotfileLib::getBasePathNoFlag

puts "Creating symbolic links for the following file paths: #{file_paths}" if options.verbose

home = Dir.home
file_paths.each { |dotfile|
  path, file = dotfile.split(",")

  src = "#{base_path}/#{path}"
  dst = "#{home}/#{file}"

  if !options.debug
    puts "ln -s #{src} #{dst}" if options.verbose
    FileUtils.ln_s(src, dst)
  else
    puts "==== DRY RUN: ln -s #{src} #{dst} ====" if options.debug
  end
}
