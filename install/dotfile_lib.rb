#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'pp'

module DotfileLib
  @personal_file_paths = [
      'i3,.i3',
      'vim,.vim',
      'vimrc,.vimrc',
      'prezto,.zprezto',
      'xinitrc,.xinitrc',
      'Xresources,.Xresources',
      'pentadactylrc,.pentadactylrc',
      'zpreztorc,.zpreztorc',
      'zprofile,.zprofile',
      'zshrc,.zshrc',
      'prezto/runcoms/zlogin,.zlogin',
      'prezto/runcoms/zlogout,.zlogout',
      'prezto/runcoms/zshenv,.zshenv'
  ]

  @work_file_paths = [
      'dotfiles/vim,.vim',
      'dotfiles/vimrc,.vimrc',
      'dotfiles/prezto,.zprezto',
      'dotfiles/pentadactylrc,.pentadactylrc',
      'dotfiles/zpreztorc,.zpreztorc',
      'zprofile,.zprofile',
      'zshrc,.zshrc',
      'dotfiles/prezto/runcoms/zlogin,.zlogin',
      'dotfiles/prezto/runcoms/zlogout,.zlogout',
      'dotfiles/prezto/runcoms/zshenv,.zshenv',
      'bin,bin'
      'ideavimrc,.ideavimrc'
  ]

  def self.personal_file_paths
    @personal_file_paths
  end # end personal_file_paths()

  def self.work_file_paths
    @work_file_paths
  end # end work_file_paths()

  def self.validateOpts(options)
    if options.personal && options.work
      puts "Can't specify both personal and work!"
      exit
    elsif !options.personal && !options.work
      puts "Need to specify either personal or work!"
      exit
    end
  end # validateOpts()

  def self.getBasePathNoFlag
    home = Dir.home

    if Dir.exists?("#{home}/.workdotfiles")
      base_path = "#{home}/.workdotfiles"
    elsif Dir.exists?("#{home}/.dotfiles")
      base_path = "#{home}/.dotfiles"
    else
      # TODO: check if 'dotfiles' or 'workdotfiles' exists... if so, rename?
      # uh oh!
      puts "Couldn't get basepath. Neither .dotfiles or .workfiles exist in #{home}."
      exit
    end

    base_path
  end # getBasePathNoFlag()

  def self.createSymLinks
  end # createSymLinks()

  def self.removeSymLinks
  end # removeSymLinks()

  def DotfileLib.parse(args = ARGV)
    # defaults
    options = OpenStruct.new

    # parse options
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: installDotfiles.rb [-lmvd]"

      opts.on("-p", "--personal", "Install personal dotfiles") { options.personal = true }
      opts.on("-m", "--work", "Install work dotfiles. Note, you'll need access to C42 stash. :)") { options.work = true }
      opts.on("-v", "--verbose", "Verbose logging") { options.verbose = true }
      opts.on("-d", "--debug", "Enables debug; doesn't actually write any files to disk. Implies verbose.") { options.debug = true; options.verbose = true }
    end
    opts.parse! args

    options
  end # parse()
end # class DotfileLib
