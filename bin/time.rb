#!/usr/bin/env ruby -Iapp -Ilib

require 'console_access.rb'
require 'yaml'

app = ConsoleAccess.new(show_cursor: false)
app.send_event(ConsoleAccess::Event.new(:update_screen))
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

app.register_event(:update_screen){ |event|
  time = Time.now
  seconds = time - start_time
  event_string = (loop_count.to_f / seconds.to_f).to_i.to_s + " per second"
  app.move_to_pos(((app.window_width - time.to_s.length)  / 2), 0)
  app.print_string(event_string)
  app.move_to_pos(0,0)
}

app.register_event(:keyboard) { |event|
  # Ctrl<C>, Ctrl<Z>, Enter, or <ESC>
  if [13,3,26].include?(event.data.char)
    app.quit = true
  end
}

#app.register_event(:redraw_screen){
#  app.write_buffer
#}
#
app.run_loop 
