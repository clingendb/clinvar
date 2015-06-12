# 
#
# @Author Xin Feng
# @Date 05/15/2015
#
#
#
require 'kb_model_to_clinvar_parser_json'
require 'para_check'
require 'json'
ParaCheck.require(1,'kb.doc.model.tsv')
parser = KBModelToClinVarParserJson.new
puts ((parser.run(ARGV[0]).to_json))

