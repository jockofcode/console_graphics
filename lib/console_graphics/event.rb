class ConsoleGraphics
  class Event
    attr_accessor :type, :method, :data
    def initialize(type = nil)
      @type = type
      @method = nil
      @data = OpenStruct.new
    end

    def type=(new_type)
      @type = new_type.to_sym
    end
  end
end
