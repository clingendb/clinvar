#
# @Author Xin Feng
# @Date 05/19/2015
#
#
#
require 'clinvar_tokenized_uploader_to_file'
require 'para_check'
require 'json'
require 'logging'

ParaCheck.require(2,'clinvar.xml kb.doc.model.json')
Logging.logger.root.appenders = Logging.appenders.stderr
Logging.logger.root.level = :info
parser = ClinVarXMLTokenizedUploaderToFile.new(ARGV[0],ARGV[1])
parser.run

