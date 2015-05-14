# Compile all ids in clinvar xml
#
# @Author Xin Feng
# @Date 05/14/2015
#
#
#
require_relative 'clinvar_id_compiler'
require 'para_check'
ParaCheck.require(1,'clinvar.xml')
compiler = ClinVarIDCompiler.new(ARGV[0])
compiler.run

