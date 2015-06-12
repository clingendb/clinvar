# Modify the value of root items in a list for 
# a KB doc
# @Author Xin Feng
# @Date 02/24/2015
# @Email xinf@bcm.edu
#


class ListRootItemValueModifier
  
  def initialize()
  end

  def modifyIDs(kbHash)
    addIDToItemsInAList(kbHash)
  end

  protected
  def generate
    ""
  end

  private
  def addIDToItemsInAList(kbHash)
    kbHash.each do |key, value|
      if value.is_a?(Hash)
        addIDToItemsInAList(value)
      elsif value.is_a?(Array)
        value.each do |valValue|
          rootItemKey = valValue.keys.first
          valValue[rootItemKey]["value"] = generate()
          addIDToItemsInAList(valValue)
        end
      end
    end

    return kbHash
  end

end
