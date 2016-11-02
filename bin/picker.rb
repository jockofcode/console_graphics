#!/usr/bin/env ruby -Iapp -Ilib
require 'bundler/setup'
require 'YAML'
require 'pallet.rb'

filename = ARGV[0] || "pallet.yml"

