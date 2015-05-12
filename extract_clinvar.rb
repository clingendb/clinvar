# Get just an element
#
# @Author Xin Feng
# @Date 05/12/2015
#
#
#
require_relative 'clinvar_tokenized_extractor'
require 'progressPrinter'
require 'logging'
require 'para_check'

ParaCheck.require(2, 'clinvar.file.xml clinvar.set.id')

pp= ClinVarXMLTokenizedExtractor.new(ARGV[0], ARGV[1])
pp.run


