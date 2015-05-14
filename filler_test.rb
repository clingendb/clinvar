# cut from just an element
#
# @Author Xin Feng
# @Date 05/12/2015
#
#
#
require 'recursive_filler'
require 'para_check'
require 'nokogiri'

filler = RecursiveFiller.new()
xml = Nokogiri::XML(File.open(ARGV[0]))
h = {"clinical_sig,/ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance"=>{'assertion'=>"./Description"},
     'observations,sample_id,/ClinVarSet/ReferenceClinVarAssertion/ObservedIn'=>[
       {'origin'=>'./Sample/Origin'},
       {'method_types,method_type_id,./Method/MethodType'=>[{'method'=>'.'}]}
]
}
#h = { 'observations,sample_id,/ClinVarSet/ReferenceClinVarAssertion/ObservedIn'=>[
#       {'origin'=>'./Sample/Origin'},
 #      {'method_types,method_type_id,./Method/MethodType'=>[{'method'=>'.'}]}
#]
#}
puts "final json:\n"+filler.fill(xml,h).inspect

