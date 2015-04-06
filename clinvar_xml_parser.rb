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
      #get_clinical_significance
      #get_observations
      #get_alleles
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

  def get_value(xpath)
    v = @cc.get_value(xpath)
    if v.nil?
      puts "gaga1"
      @nil_log << xpath  
    elsif v.empty?
      puts "gaga2"
      @empty_log << xpath
    end
    return v
  end

end
