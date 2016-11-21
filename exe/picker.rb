#!/usr/bin/env ruby -Iapp -Ilib
require 'bundler/setup'
require 'console_graphics'

app = ConsoleGraphics::EventLoop.new
start_time = Time.now
last_coords = [0,0]

app.run { |event|
  if event
    last_coords = [event.data.cols,event.data.lines] if event.type == :mouse && event.method == :button_down
    screen_size=[(app.window_width/2), app.window_height]
    app.quit = true if [13,3,26].include?(event.data.char) # Ctrl<C>, Ctrl<Z>, Enter

    app.move_to_pos(*last_coords)
    app.select_color(1)
    print_char = "#"
    app.print_string(print_char)
    app.select_color(0)

    # Update status at the bottom, even if no event happened
    status = "#{last_coords.first}x#{last_coords.last} Press Enter to Quit"
    app.move_to_pos((app.window_width - status.length) / 2, app.window_height)
    app.print_string(status)
    # app.write_buffer
  end
}
