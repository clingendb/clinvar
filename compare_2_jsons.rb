# Compare two jsons
#
# @Author Xin Feng
# @Date 05/13/2015
#
#
#
require 'para_check'
require 'json-compare'
require 'json'

ParaCheck.require(2, 'json1.json json2.json')

j1 = JSON.parse(File.read(ARGV[0]))
j2 = JSON.parse(File.read(ARGV[1]))
result = JsonCompare.get_diff(j1,j2)
puts result
