# cut from just an element
#
# @Author Xin Feng
# @Date 05/12/2015
#
#
#
require_relative 'clinvar_tokenized_cutter'
require 'para_check'

ParaCheck.require(2, 'clinvar.file.xml clinvar.set.id')

pp= ClinVarXMLTokenizedCutter.new(ARGV[0], ARGV[1])
pp.run


