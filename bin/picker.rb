#!/usr/bin/env ruby -Iapp -Ilib
require 'bundler/setup'
require 'pallet.rb'
require 'pry-byebug'
require 'console_access.rb'

app = ConsoleAccess.new
start_time = Time.now
app.run_loop
#app.run_loop{ :quit if Time.now - start_time > 10.0 # Auto kill after 10 seconds }
