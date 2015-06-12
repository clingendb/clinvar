# Transform a ruby hash to a KB hash
# based on its structure
# @Author Xin Feng
# @Date 02/10/2015
# @Email xinf@bcm.edu
#

# The id of items in a list is automatcailly added by the autoID
# And thus we dont encourage using the rootItem of a listItem to
# encode information other than the surrogate ID


require 'json'

class  JsonToKB

  def initialize(rootIDName, id)
    @root = rootIDName
    @id = id
  end

  def to_kb(hash)
    r = {@root=>{"value"=>@id.to_s,"properties"=>iterativeTransform(hash)}}
  end

  def to_kb_json(hash)
    to_kb(hash).to_json
  end

  def id(id)
    @id = id
  end

  private
  def iterativeTransform(p)
    r= {}
    p.each {|key, value|
      if value.is_a?(Hash) 
        r[key] = {"value"=>""}
        r[key]["properties"] = iterativeTransform(value) 
      elsif value.is_a?(Array)
        r[key] = {"items"=>[]}
        value.each_with_index do |v,ind|
          r[key]["items"] << iterativeTransform(v)
        end
      else
        r[key] = {"value"=>value}
      end
    }
    return r 
  end
  
end
