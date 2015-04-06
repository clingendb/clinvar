# Parse all clinvar data
#
# @Author Xin Feng
# @Date 04/06/2015
#
#
#
require_relative 'clinvar_xml_parser'
require 'progressPrinter'
require 'logging'
require 'para_check'

ParaCheck.require(1, 'clinvar.file.xml')

pp= ClinVarXMLParser.new(ARGV[0])
pp.run
pp.print_stats


