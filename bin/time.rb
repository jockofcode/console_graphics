#!/usr/bin/env ruby -Iapp -Ilib
require 'bundler/setup'
require 'event_loop.rb'
require 'yaml'

app = EventLoop.new(show_cursor: false)
app.send_event(EventLoop::Event.new(:update_screen))
start_time = Time.now
quit = false

last_time_checked = Time.now
loop_count = 0
start_time = last_time_checked
update_frequency = (1.0 / 60.0)

app.register_event_trigger(:update_screen){
  now = Time.now
  loop_count += 1
  if loop_count > 10_000_000
    loop_count = 1
    start_time = last_time_checked = now
  end

  if now - last_time_checked > update_frequency
    last_time_checked = now
  else
    nil
  end
}

app.register_event_trigger(:bad_trigger){
  # example of a slow event that could mess up everything :)
  sleep 1.0/90.0
  nil
}

app.register_event(:update_screen){ |event|
  time = Time.now
  seconds = time - start_time
  app.clear_screen
  event_string = (loop_count.to_f / seconds.to_f).to_i.to_s + " per second"
  app.move_to_pos(((app.window_width - time.to_s.length)  / 2), 0)
  app.print_string(event_string)
  app.move_to_pos(0,0)
  app.send_event(EventLoop::Event.new(:redraw_screen))
}

app.register_event(:keyboard) { |event|
  # Ctrl<C>, Ctrl<Z>, Enter, or <ESC>
  if [13,3,26].include?(event.data.char)
    app.quit = true
  end
}

# This wasn't making a difference.... :(
# app.register_event(:redraw_screen){
#   app.write_buffer
# }

app.run 
