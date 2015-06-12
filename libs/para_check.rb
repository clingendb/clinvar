# Check parameters of a ruby script
# @Author Xin Feng
# @Date 02/11/2015
# @Email xinf@bcm.edu
#

class ParaCheck
  
  def self.require(numOfPara, usageMsg)
    if(ARGV.length < numOfPara)
      $stderr.puts "ruby: #{$0} "+usageMsg
      exit
    end
  end

end
