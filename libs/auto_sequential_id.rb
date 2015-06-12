# Add auto integer IDs to items in a list 
# @Author Xin Feng
# @Date 02/23/2015
# @Email xinf@bcm.edu
#

# The id of items in a list is automatcailly added by the autoID
# And thus we dont encourage using the rootItem of a listItem to
# encode information other than the surrogate ID


require 'sequential_integer_generator'
require 'list_root_item_value_modifier'

class AutoSequentialID < ListRootItemValueModifier
  def initialize
    SequentialIntegerGenerator.reset()
  end
  protected
  def generate
    SequentialIntegerGenerator.get().to_s
  end
end
