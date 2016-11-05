require 'pallet.rb'

p = Pallet.new
p.pallet = {"fire on ocean"=>{:index=>1, :bg=>4, :fg=>1}, "blood on water"=>{:index=>1, :bg=>4, :fg=>1}}
p.add_color("fire on ocean", 2,4)
puts "It Works!!!" if p.pallet == {"fire on ocean"=>{:index=>2, :bg=>4, :fg=>2}, "blood on water"=>{:index=>1, :bg=>4, :fg=>1}}
