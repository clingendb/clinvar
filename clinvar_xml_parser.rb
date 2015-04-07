# Parse all clinvar data
#
# @Author Xin Feng
# @Date 04/06/2015
#
#
#
require 'xpath_parser'
require 'progressPrinter'
require 'logging'

class ClinVarXMLParser
  def initialize(file)
    pp = XpathParser.new(XpathParser::open_with_nokogiri(ARGV[0]))
    @clinvar_set = pp.get('//ClinVarSet')
    @log = Logging.logger(STDERR)
    @log.level = :debug
    @log.info 'XML file parsing done'
    @h = {}
    @nil_log= []
    @empty_log= []
  end

  def run
    @clinvar_set.each do |clinvar|
      @cc = XpathParser.new(clinvar)
      get_basic_info
      get_clinical_significance
      get_observations
      get_alleles
      #get_diseases
    end
  end


  def get_basic_info
   r = {'title'=>get_value('//ClinVarSet/Title'),'record_status'=>get_value('//ClinVarSet/RecordStatus'),
    'record_dates'=>
     {'date_created'=>get_value('//ClinVarSet/ReferenceClinVarAssertion/@DateCreated'),
      'date_last_updated'=>get_value('//ClinVarSet/ReferenceClinVarAssertion/@DateLastUpdated')
     },
    'rcv_accession'=>
     {'accession'=>get_value('//ClinVarSet/ReferenceClinVarAssertion/ClinVarAccession/@Acc'),
     'date_last_updated'=>get_value('//ClinVarSet/ReferenceClinVarAssertion/ClinVarAccession/@DateLastUpdated'),
     'rcv_version'=>get_value('//ClinVarSet/ReferenceClinVarAssertion/ClinVarAccession/@Version'),
     'status'=>get_value('//ClinVarSet/ReferenceClinVarAssertion/RecordStatus')
     }
    }

   puts r
  end

  def get_clinical_significance
    #-  clinical_significance GenboreeKB Place Holder
    #-- date_last_evaluated //ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance/@DateLastEvaluated
    #-- review_status //ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance/ReviewStatus
    #-- assertion //ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance/Description
    #-  assertion_type  //ClinVarSet/ReferenceClinVarAssertion/Assertion/@Type
    r={
    'clinical_significance'=>{
      'date_last_evaluated'=>get_value('//ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance/@DateLastEvaluated'),
      'review_status'=>get_value('//ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance/ReviewStatus'),
      'assertion'=>get_value('//ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance/Description')
    },
      'assertion_type'=>get_value('//ClinVarSet/ReferenceClinVarAssertion/Assertion/@Type')
    }
    puts r
  end

  def get_observations
    #*  observations  GenboreeKB Place Holder
    #*- sample_id GenboreeKB Place Holder
    #*--  origin  //ClinVarSet/ReferenceClinVarAssertion/ObservedIn/Sample/Origin
    #*--  species //ClinVarSet/ReferenceClinVarAssertion/ObservedIn/Sample/Species
    #*--  affected_status //ClinVarSet/ReferenceClinVarAssertion/ObservedIn/Sample/AffectedStatus
    #*--  number_tested //ClinVarSet/ReferenceClinVarAssertion/ObservedIn/Sample/NumberTested
    #*--  method_type //ClinVarSet/ReferenceClinVarAssertion/ObservedIn/Method/MethodType
    r={
      'observations'=> []
    }
    samples = get('//ClinVarSet/ReferenceClinVarAssertion/ObservedIn')
    samples.each do |s|
      @log.debug "sample:#{s}"
      r['observations'] << {
      'sample_id'=>{
        'origin'=>get_doc_value(s,'./Sample/Origin'),
        'species'=>get_doc_value(s,'./Sample/Species'),
        'affected_status'=>get_doc_value(s,'./Sample/AffectedStatus'),
        'number_tested'=>get_doc_value(s,'./Sample/NumberTested'),
        'method_type'=>get_doc_value(s,'./Method/MethodType')
      }
      }
    end
    puts r
  end

  def get_alleles
    get_allele_basic_info
   # get_molecuar_consequence
   # get_locations
   # get_genes
  end

  def get_allele_basic_info
    #*  alleles GenboreeKB Place Holder
    #*- allele_id GenboreeKB Place Holder
    get_allele_cross_references
    get_misc_allele_info
  end
  
  def get_allele_cross_references
    #*-*  cross_reference GenboreeKB Place Holder
    #*-*- cross_reference_id  GenboreeKB Place Holder
    #*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/XRef/@DB
    #*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/XRef/@ID
    #*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/XRef/@Type
    r={
      'cross_reference'=> []
    }
    references = get('//ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/XRef')
    references.each do |s|
      @log.debug "reference:#{s}"
      r['cross_reference'] << {
      'cross_reference_id'=>{
        'db_name'=>get_doc_value(s,'./@DB'),
        'db_id'=>get_doc_value(s,'./@ID'),
        'type'=>get_doc_value(s,'./@Type'),
      }
      }
    end
    puts r
  end

  def get_misc_allele_info
    #*--  type  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/@Type
    #*--  name  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/Name/ElementValue[@Type="preferred name"]
    #*-*  hgvs  GenboreeKB Place Holder
    #*-*- hgvs_id GenboreeKB Place Holder
    #*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[starts-with(@Type, 'HGVS')]/@Type
    #*-*--  value //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[starts-with(@Type, 'HGVS')]
    r={
      'hgvs'=> []
    }
    hgvs = get("//ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[starts-with(@Type, 'HGVS')]")
    hgvs.each do |s|
      @log.debug "hgvs:#{s}"
      r['hgvs'] << {
      'hgvs_id'=>{
        'type'=>get_doc_value(s,'./@Type'),
        'value'=>get_doc_value(s,'.'),
      }
      }
    end
    puts r

  end

  def print_stats
    print_log(@nil_log,"The following paths yielded nil values")
    print_log(@empty_log,"The following paths yielded empty values")
  end

  private
  def print_log(val,msg="")
    if val.length > 0
      @log.info msg 
      val.each do |ni|
        @log.info ni
      end
    end
  end

  def get(xpath)
    v = @cc.get(xpath)
    if v.nil?
      @nil_log << xpath  
    elsif v.empty?
      @empty_log << xpath
    end
    return v
  end

  def get_array(xpath)
    v = @cc.get_content(xpath)
    if v.nil?
      @nil_log << xpath  
    elsif v.empty?
      @empty_log << xpath
    end
    return v
  end

  def get_doc_value(doc, xpath)
    c = XpathParser.new(doc)
    v = c.get_value(xpath)
    if v.nil?
      @nil_log << xpath  
    elsif v.empty?
      @empty_log << xpath
    end

    if v.nil?
      return ""
    end
    return v
  end

  def get_value(xpath)
    v = @cc.get_value(xpath)
    if v.nil?
      @nil_log << xpath  
    elsif v.empty?
      @empty_log << xpath
    end
    return v
  end

end
