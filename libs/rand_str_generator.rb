# Generates a random str
# @Author Xin Feng
# @Date 02/24/2015
# @Email xinf@bcm.edu
#

class RandomStrGenerator

  def self.get(length)
    ('a'..'z').to_a.concat(('0'..'9').to_a).shuffle[0,length].join
  end

end
