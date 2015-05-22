#
# @Author Xin Feng
# @Date 05/19/2015
#
#
#
require_relative 'clinvar_tokenized_uploader'
require 'para_check'
require 'json'
require 'logging'

ParaCheck.require(2,'clinvar.xml kb.doc.model.json')
parser = ClinVarXMLTokenizedUploader.new(ARGV[0],ARGV[1])
parser.configure_api('acmg-apiTest','test','clinvar_test0.8')
Logging.logger.root.appenders = Logging.appenders.stderr
Logging.logger.root.level = :info
parser.run

