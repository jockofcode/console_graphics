#!/usr/bin/env ruby -Iapp -Ilib

require 'bundler/setup'
require 'event_loop.rb'
require 'yaml'

app = EventLoop.new(show_cursor: false)
def print_border(app)
  app.move_to_pos(0,0)
  app.print_string('#')
  app.move_to_pos(app.window_width - 1,0)
  app.print_string('#')
  app.move_to_pos(app.window_width - 1,app.window_height)
  app.print_string('#')
  app.move_to_pos(0,app.window_height)
  app.print_string('#')
end

app.on_event(:keyboard, "Generic Keypress Responder") { |event|
  app.clear_screen
  app.move_to_pos(0,0)
  event_string = event.to_yaml
  app.print_string(event_string)
  print_border(app)
  # Ctrl<C>, Ctrl<Z>, Enter, or <ESC>
  if [13,3,26].include?(event.data.char)
    app.quit = true
  end
}

app.on_event(:special_keys, "Generic ArrowKey Responder") { |event|
  app.clear_screen
  app.move_to_pos(0,0)
  event_string = event.to_yaml
  app.remove_event_responder("Generic ArrowKey Responder")
  app.print_string(event_string)
}

# This wasn't making a difference.... :(
app.on_event(:redraw_screen, "Generic Redraw Responder"){
  app.write_buffer
}

app.run 
