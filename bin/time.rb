#!/usr/bin/env ruby -Iapp -Ilib

require 'console_access.rb'
require 'yaml'

app = ConsoleAccess.new
app.show_cursor false
app.send_event(ConsoleAccess::Event.new(:update_screen))
start_time = Time.now
quit = false

last_time_checked = Time.now
app.register_event_check(:update_screen){
  if Time.now - last_time_checked > 1
    last_time_checked = Time.now
  else
    nil
  end
}

app.run_loop { |window, events|
  event = events.shift

  time = Time.now.to_s
  event_string = event.to_yaml
  app.move_to_pos(((app.window_width - time.length)  / 2), 0)
  app.print_string(event_string)
  app.move_to_pos(0,0)

  # Ctrl<C>, Ctrl<Z>, Enter, or <ESC>
  if event && event.type == :keyboard && [13,3,26].include?(event.data.char) 
    quit = true
  end


  app.write_buffer
  :quit if quit
}
