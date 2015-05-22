# 
#
# @Author Xin Feng
# @Date 05/15/2015
#
#
#
require_relative 'kb_model_to_clinvar_parser_json'
require 'para_check'
require 'json'
ParaCheck.require(1,'kb.doc.model.tsv')
parser = KBModelToClinVarParserJson.new
#$stderr.puts JSON.pretty_generate((parser.run(ARGV[0])))
#$stderr.puts ((parser.run(ARGV[0])))
puts ((parser.run(ARGV[0]).to_json))

