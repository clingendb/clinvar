#
# @Author Xin Feng
# @Date 05/19/2015
#
#
#
require_relative 'clinvar_tokenized_uploader_to_file'
require 'para_check'
require 'json'
require 'logging'

ParaCheck.require(2,'clinvar.xml kb.doc.model.json')
parser = ClinVarXMLTokenizedUploaderToFile.new(ARGV[0],ARGV[1])
Logging.logger.root.appenders = Logging.appenders.stderr
Logging.logger.root.level = :info
parser.run

