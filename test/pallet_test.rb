require 'console_graphics/pallet.rb'

p = ConsoleGraphics::Pallet.new
p.pallet = {"fire on ocean"=>{:index=>1, :fg=>1, :bg=>4}, "blood on water"=>{:index=>1, :fg=>1, :bg=>4}}
p.add_color("fire on ocean", 2,4)
puts "It Works!!!" if p.pallet == {"fire on ocean"=>{:index=>2, :fg=>2, :bg=>4}, "blood on water"=>{:index=>1, :fg=>1, :bg=>4}}
