#!/usr/bin/env ruby -Iapp -Ilib
require 'bundler/setup'
require 'pallet.rb'
require 'pry-byebug'

current_pallet = Pallet.load_from_file("pallet.yml")
binding.pry
current_pallet.set_active_pallet


cur_line = Curses.lines / 2

#whole_window = Curses::Window.new(*([0] * 4))
whole_window = Curses::Window.new(0,0,0,0)

current_pallet.pallet.keys.each{|key|
  color_name = key
  win.attrset(Curses.color_pair(current_pallet.find_slot_by_name(key)[:index]))
  whole_window.setpos(cur_line, Curses.cols / 2)
  whole_window.addstr(color_name)
  cur_line += 1
}

#whole_window.attrset(Curses.color_pair(1))

whole_window.refresh
whole_window.getch
whole_window.close
