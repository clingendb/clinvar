# Add auto integer IDs to items in a list 
# It follows the syntax:
# prefix_randstr_postfix
# @Author Xin Feng
# @Date 02/24/2015
# @Email xinf@bcm.edu
#

# The id of items in a list is automatcailly added by the autoID
# And thus we dont encourage using the rootItem of a listItem to
# encode information other than the surrogate ID

require 'rand_str_generator'
require 'list_root_item_value_modifier'

class AutoRandStrID < ListRootItemValueModifier
  
  def initialize()
    @length = 8
    @pre = ""
    @post = ""
    @delimiter = "-"
  end

  def setPreAndPostfix(pre,post)
    @pre = pre
    @post = post
  end

  def setRandStrLength(l)
    @length = l
  end

  def setDelimiter(d)
    @delimiter = d
  end

  protected
  def generate
    [@pre,RandomStrGenerator.get(@length), @post ].join(@delimiter)
  end
end
