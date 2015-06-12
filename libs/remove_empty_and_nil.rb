# Delete {}, nil, [] and ""
# from a KB json. usually use
# this after you get a kb HASH
#
# @Author Xin Feng
# @Date 05/19/2015
# @Email xinf@bcm.edu
#


class RemoveEmptyAndNilKB

  def self.process(p)
    p.each {|key, value|
      if value.is_a?(Hash) 
         process(value) 
         if value == {}
           p.delete(key)
         end
      elsif value.is_a?(Array)
        value.each_with_index do |v,ind|
          process(v)
        end
        if value == []
          p.delete(key) 
        end
      else
        if value.nil? 
          p.delete(key)
        else
          if value.class == String.class
            if value.empty?
              p.delete(key)
            end
          end
        end
      end
    }
    return p 
  end
  
end
