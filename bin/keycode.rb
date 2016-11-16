#!/usr/bin/env ruby -Iapp -Ilib

require 'console_access.rb'
require 'yaml'

app = ConsoleAccess.new(show_cursor: false)
quit = false

app.register_event(:keyboard) { |event|
  app.clear_screen
  app.move_to_pos(0,0)
  event_string = event.to_yaml
  app.print_string(event_string)
  # Ctrl<C>, Ctrl<Z>, Enter, or <ESC>
  if [13,3,26].include?(event.data.char)
    app.quit = true
  end
}

app.register_event(:special_keys) { |event|
  app.clear_screen
  app.move_to_pos(0,0)
  event_string = event.to_yaml
  app.print_string(event_string)
}

# This wasn't making a difference.... :(
app.register_event(:redraw_screen){
  app.write_buffer
}

app.run_loop 
