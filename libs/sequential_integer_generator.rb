# Generates an integer starting from 1
# @Author Xin Feng
# @Date 02/23/2015
# @Email xinf@bcm.edu
#

class SequentialIntegerGenerator

  @@i = 0 

  def self.reset()
    @@i = 0
  end

  def self.get()
    @@i += 1
    @@i
  end

end
