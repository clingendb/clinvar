# Compile a table of ids
#
# clinvar_set_id  RCVID RCV-MeasureSetID RCV-MeasureSet-MeasureID1,ID2 SCVID1,SCVID2 
# @Author Xin Feng
# @Date 05/14/2015
#
#
#
require 'progressPrinter'
require 'xpath_parser'
require 'logging'
require_relative 'clinvar_tokenized_parser'

class ClinVarIDCompiler << ClinVarXMLTokenizedParser
  def parse str
    @xml_parser = XpathParser.new(nil)
    @xml_parser.read_string(str)
    @clinvar_set_id = @xml_parser.get_value('//ClinVarSet/@ID')
    @rcv = @xml_parser.get_value('//ClinVarSet/ReferenceClinVarAssertion/ClinVarAccession/@Acc')
    @measure_set_id = @xml_parser.get_value('//ClinVarSet/ReferenceClinVarAssertion/MeasureSet/@ID')
    @measure_ids = @xml_parser.get_content('//ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/@ID')
    @scvs = @xml_parser.get_content('//ClinVarSet/ClinVarAssertion/ClinVarAccession/@Acc')
   
    puts [
      @clinvar_set_id,
      @rcv,
      @measure_set_id,
      @measure_ids.join(','),
      @scvs.join(',')
    ].join("\t")

  end

end
