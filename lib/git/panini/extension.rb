require 'pathname'

class Pathname
  def is_child_of?(other)
    other.ascend do |pathname|
      return true if pathname == self
    end
    false
  end
end
