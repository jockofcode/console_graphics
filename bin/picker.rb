#!/usr/bin/env ruby -Iapp -Ilib
require 'bundler/setup'
require 'pallet.rb'
require 'pry-byebug'
require 'console_access.rb'

main_loop = ConsoleAccess.new
main_loop.run_loop
