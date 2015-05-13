# cut from just an element
#
# @Author Xin Feng
# @Date 05/12/2015
#
#
#
require_relative 'recursive_filler'
require 'para_check'
require 'nokogiri'

filler = RecursiveFiller.new()
xml = Nokogiri::XML(File.open(ARGV[0]))
h = {"clinical_sig,/ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance"=>{'assertion'=>"./Description"}}
puts filler.fill(xml,h)

