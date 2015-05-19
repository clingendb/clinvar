# cut from just an element
#
# @Author Xin Feng
# @Date 05/12/2015
#
#
#
require 'recursive_filler'
require 'auto_rand_str_id'
require 'para_check'
require 'nokogiri'
require 'json_to_kb'
require 'api_uploader'
require 'logging'

Logging.logger.root.appenders = Logging.appenders.stderr
Logging.logger.root.level = :info
ParaCheck.require(2,'clinvar.xml model.json')
filler = RecursiveFiller.new()
xml = Nokogiri::XML(File.open(ARGV[0]))
h = {"clinical_sig,/ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance"=>{'assertion'=>"./Description"},
     'observations,sample_id,/ClinVarSet/ReferenceClinVarAssertion/ObservedIn'=>[
       {'origin'=>'./Sample/Origin'},
       {'method_types,method_type_id,./Method/MethodType'=>[{'method'=>'.'}]}
]
}
#h = { 'observations,sample_id,/ClinVarSet/ReferenceClinVarAssertion/ObservedIn'=>[
#       {'origin'=>'./Sample/Origin'},
 #      {'method_types,method_type_id,./Method/MethodType'=>[{'method'=>'.'}]}
#]
#}
h= {"rcv_accession,./ReferenceClinVarAssertion/ClinVarAccession"=>{"rcv_version"=>"./@Version", "date_updated"=>"./@DateUpdated", "accession"=>"./@Acc"}, "record_dates,./ReferenceClinVarAssertion"=>{"date_last_updated"=>"./@DateLastUpdated", "date_created"=>"./@DateCreated"}, "record_status"=>"./RecordStatus", "title"=>"./Title"}
h= {"record_dates,./ReferenceClinVarAssertion"=>{"date_last_updated"=>"./@DateLastUpdated", "date_created"=>"./@DateCreated"}, "record_status"=>"./RecordStatus", "title"=>"./Title"}
h= {"DocumentID,//ClinVarSet"=>{"rcv_accession,./ReferenceClinVarAssertion/ClinVarAccession"=>{"rcv_version"=>"./@Version", "date_updated"=>"./@DateUpdated", "accession"=>"./@Acc"}, "record_dates,./ReferenceClinVarAssertion"=>{"date_last_updated"=>"./@DateLastUpdated", "date_created"=>"./@DateCreated"}, "record_status"=>"./RecordStatus", "title"=>"./Title"}}
#h= {"DocumentID,/ClinVarSet"=>{"title"=>"./ReferenceClinVarAssertion"}}
h={"DocumentID,//ClinVarSet"=>{"observations,sample_id,./ReferenceClinVarAssertion/ObservedIn"=>[{"origin"=>"./Sample/Origin"}, {"species"=>"./Sample/Species"}, {"affected_status"=>"./Sample/AffectedStatus"}, {"number_tested"=>"./Sample/NumberTested"}, {"method_types,method_type_id,./ReferenceClinVarAssertion/ObservedIn/Method"=>[{"method"=>"./MethodType"}]}], "assertion_type"=>"./ReferenceClinVarAssertion/Assertion/@Type", "clinical_significance,./ReferenceClinVarAssertion/ClinicalSignificance"=>{"assertion"=>"./Description", "review_status"=>"./ReviewStatus", "date_last_evaluated"=>"./@DateLastEvaluated"}, "rcv_accession,./ReferenceClinVarAssertion/ClinVarAccession"=>{"rcv_version"=>"./@Version", "date_updated"=>"./@DateUpdated", "accession"=>"./@Acc"}, "record_dates,./ReferenceClinVarAssertion"=>{"date_last_updated"=>"./@DateLastUpdated", "date_created"=>"./@DateCreated"}, "record_status"=>"./RecordStatus", "title"=>"./Title"}}
h = JSON.parse(File.read(ARGV[1]))
#$stderr.puts "The parsed json doc model is\n"+h.inspect
#puts "final json:\n"+filler.fill(xml,h).inspect
ga = JsonToKB.new('DocumentID',1)
id_adder = AutoRandStrID.new()
id_adder.setPreAndPostfix('snp','id')
uploader = APIUploader.new()
uploader.configure("acmg-apiTest","test",'clinvar_xml0.7')
uploader.set_resource_path('doc/1?')
hash = filler.fill(xml,h)['DocumentID']
filler.report_nil_and_empty_paths
#DocumentID.observations.[0].sample_id.number_of_observations
hash['observations'].each do |ar|
  ar['sample_id']['number_of_observations'] = 0
end
json= id_adder.modifyIDs(ga.to_kb(hash))

uploader.upload(id_adder.modifyIDs(json))
puts uploader.serverStatusMsg
