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
require 'json'
require 'json_to_kb'
require 'auto_rand_str_id'

class ClinVarXMLParser

  def initialize(nokogiri_obj)
    @file = 'test_file'
    @pp = XpathParser.new(nokogiri_obj)
    @clinvar_set = @pp.get('/ClinVarSet')
    @log = Logging.logger(STDERR)
    @log.level = :debug
    @h = {}
    @nil_log= []
    @empty_log= []
    @id = 1
  end

  def run
    if @clinvar_set.length < 1
      @log.info "No docs found in\n"+@file
      @clinvar_set = @pp.get('/ClinVarSet')
      if @clinvar_set.length > 0
        @log.info "Using /ClinVarSet as the root path instead."
      else
        return
      end
    end

    dp = ProgressPrinter.new(@clinvar_set.length)
    @clinvar_set.each_with_index do |clinvar,i|
      @cc = XpathParser.new(clinvar)
      r={}
      r = get_basic_info.merge(r)
      @log.debug "after merging basic info:"+r.to_json
      r = get_clinical_significance.merge(r)
      @log.debug "after merging clinical significance:"+r.to_json
      r = get_observations.merge(r)
      @log.debug "after merging observations:"+r.to_json
      @log.level =:debug
      r = get_alleles.merge(r)
      @log.debug "after merging alleles :"+r.to_json
      r = get_diseases.merge(r)
      @log.debug "after merging diseases:"+r.to_json
      r = get_scvs.merge(r)
      @log.info "Final json:"+r.to_json
      save_json(to_kb_json(r),@file+"_"+i.to_s+".json")
      dp.printProgress($stderr,i)
      if i == 100
        @log.info "program quited at 100th file"
        exit
      end
    end
  end


  def get_basic_info
    r = {'title'=>get_value('./Title'),
         'record_status'=>get_value('./RecordStatus'),
         'record_dates'=>
    {'date_created'=>get_value('./ReferenceClinVarAssertion/@DateCreated'),
     'date_last_updated'=>get_value('./ReferenceClinVarAssertion/@DateLastUpdated')
    },
    'rcv_accession'=>
    {'accession'=>get_value('./ReferenceClinVarAssertion/ClinVarAccession/@Acc'),
     'date_updated'=>get_value('./ReferenceClinVarAssertion/ClinVarAccession/@DateUpdated'),
     'rcv_version'=>get_value('./ReferenceClinVarAssertion/ClinVarAccession/@Version'),
     'status'=>get_value('./ReferenceClinVarAssertion/RecordStatus')
    }
    }

    @log.debug r
    return  r
  end

  def get_clinical_significance
    #-  clinical_significance GenboreeKB Place Holder
    #-- date_last_evaluated //ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance/@DateLastEvaluated
    #-- review_status //ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance/ReviewStatus
    #-- assertion //ClinVarSet/ReferenceClinVarAssertion/ClinicalSignificance/Description
    #-  assertion_type  //ClinVarSet/ReferenceClinVarAssertion/Assertion/@Type
    r={
      'clinical_significance'=>{
        'date_last_evaluated'=>get_value('./ReferenceClinVarAssertion/ClinicalSignificance/@DateLastEvaluated'),
        'review_status'=>get_value('./ReferenceClinVarAssertion/ClinicalSignificance/ReviewStatus'),
        'assertion'=>get_value('./ReferenceClinVarAssertion/ClinicalSignificance/Description')
      },
      'assertion_type'=>get_value('./ReferenceClinVarAssertion/Assertion/@Type')
    }
    @log.debug r
    return r
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
    @log.info "Fix the observed_data part"
    samples = get('./ReferenceClinVarAssertion/ObservedIn')
    samples.each do |s|
      methods = get_by_doc(s, './Method/MethodType')
      mt = []
      methods.each do |method|
        mt << {'method_type_id'=>{'method'=>get_doc_value(method, '.')}}  
      end

      @log.debug "sample:#{s}"
      r['observations'] << {
        'sample_id'=>{
          'origin'=>get_doc_value(s,'./Sample/Origin'),
          'species'=>get_doc_value(s,'./Sample/Species'),
          'affected_status'=>get_doc_value(s,'./Sample/AffectedStatus'),
          'number_tested'=>get_doc_value(s,'./Sample/NumberTested'),
          'method_types'=>mt,
          # 'observed_data'=>get_doc_value(s,'./ObservedData/Attribute/@integerValue')
        }
      }
    end
    @log.debug r
    return r
  end

  def get_alleles
    alleles = get('./ReferenceClinVarAssertion/MeasureSet/Measure')
    h = {'alleles'=>[]}
    old_cc = @cc #TODO: REALLY INSTRUSIVE!!!!
    alleles.each do |allele|
      @cc = XpathParser.new(allele)
      r = get_allele_basic_info
      r = get_molecuar_consequence.merge(r)
      r = get_locations.merge(r)
      r = get_genes.merge(r)
      h['alleles'] << {'allele_id'=>r}
    end
    @cc = old_cc
    return h
  end

  def get_allele_basic_info
    #*  alleles GenboreeKB Place Holder
    #*- allele_id GenboreeKB Place Holder
    r = get_misc_allele_info
    r = get_allele_cross_references.merge(r)
    return r
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
    references = get('./XRef')
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
    return r
  end

  def get_misc_allele_info
    #*--  type  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/@Type
    #*--  name  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/Name/ElementValue[@Type="Preferred"]
    #*--  genbank_location  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[@Type = "Location"]
    #*-*  hgvs  GenboreeKB Place Holder
    #*-*- hgvs_id GenboreeKB Place Holder
    #*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[starts-with(@Type, 'HGVS')]/@Type
    #*-*--  value //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[starts-with(@Type, 'HGVS')]
    r={
      'hgvs'=> []
    }
    hgvs = get("./AttributeSet/Attribute[starts-with(@Type, 'HGVS')]")
    hgvs.each do |s|
      @log.debug "hgvs:#{s}"
      r['hgvs'] << {
        'hgvs_id'=>{
          'type'=>get_doc_value(s,'./@Type'),
          'value'=>get_doc_value(s,'.'),
        }
      }
    end

    r['type'] = get_value('./@Type')
    r['name'] = get_value('./Name/ElementValue[@Type="Preferred"]')
    r['genbank_location'] = get_value('./AttributeSet/Attribute[@Type = "Location"]')

    return r
  end

  def get_molecuar_consequence
    #*-* molecular_consequences  GenboreeKB Place Holder
    #*-*-  molecular_consequence_id  GenboreeKB Place Holder
    #*-*-- value //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[@Type = "MolecularConsequence"]
    #*-*-* cross_reference GenboreeKB Place Holder
    #*-*-*-  cross_reference_id  GenboreeKB Place Holder
    #*-*-*-- db_name //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[@Type = "MolecularConsequence"]/following-sibling::XRef/@DB
    #*-*-*-- db_id //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[@Type = "MolecularConsequence"]/following-sibling::XRef/@ID
    #*-*-*-- type  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[@Type = "MolecularConsequence"]/following-sibling::XRef/@Type

    r={
      'molecular_consequences'=> {}
    }
    mc = get('./AttributeSet/Attribute[@Type = "MolecularConsequence"]')
    n = []
    mc.each do |s|
      @log.debug s.inspect
      @log.info "fix the reference part here"

      n << {
        'molecular_consequence_id'=>{
          'value'=>get_doc_value(s, '.')
        }
      }
    end
    r['molecular_consequences'] = n
    return r
  end

  def get_locations
    #*--  cytogenetic_location  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/CytogeneticLocation
    #*-*  sequence_locations  GenboreeKB Place Holder
    #*-*- location_id GenboreeKB Place Holder
    #*-*--  assembly  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/SequenceLocation/@Assembly
    #*-*--  chr //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/SequenceLocation/@Chr
    #*-*--  accession //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/SequenceLocation/@Accession
    #*-*--  start //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/SequenceLocation/@start
    #*-*--  stop  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/SequenceLocation/@stop
    #*-*--  length  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/SequenceLocation/@variantLength
    #*-*--  reference_allele  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/SequenceLocation/@referenceAllele
    #*-*--  alternative_allele  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/SequenceLocation/@alternateAllele
    r={
      'sequence_locations'=> []
    }
    references = get('./SequenceLocation')
    references.each do |s|
      @log.debug "location:#{s}"
      start=get_doc_value(s,'./@start')
      stop=get_doc_value(s,'./@stop')
      l = get_doc_value(s,'./@variantLength')
      length = l.to_i
      if l.empty?
        @log.warn "empty variant length for "+s.inspect
        length = stop.to_i - start.to_i + 1 
      end
      raise "invalid length in sequence location" if length < 1
      r['sequence_locations'] << {
        'location_id'=>{
          'assembly'=>get_doc_value(s,'./@Assembly'),
          'chr'=>get_doc_value(s,'./@Chr'),
          'accession'=>get_doc_value(s,'./@Accession'),
          'start'=>start,
          'stop'=>stop,
          'length'=>length,
          'reference_allele'=>get_doc_value(s,'./@referenceAllele'),
          'alternative_allele'=>get_doc_value(s,'./@alternateAllele'),
        }
      }
    end

    r['cytogenetic_location'] = get_value('./CytogeneticLocation')
    @log.debug r
    return r
  end

  def get_genes
    #*--  gene  GenboreeKB Place Holder
    #*--- name  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/Name/ElementValue[@Type="Preferred"]
    #*--- symbol  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/Symbol/ElementValue[@Type="Preferred"]

    h = {'genes'=>[]}
    genes = get('./MeasureRelationship[@Type="variant in gene"]')
    old_cc = @cc
    genes.each do |gene|
      @cc = XpathParser.new(gene)
      r = {}
      r['name'] = get_value('./Name/ElementValue[@Type="Preferred"]')
      r['symbol'] = get_value('./Symbol/ElementValue[@Type="Preferred"]')
      @log.info "not finished in the gene part yet"
      # get_gene_comments.merge(r)
      r = get_gene_locations.merge(r)
      #r = get_gene_cross_references.merge(r)
      h['genes'] << {'gene_id'=>r}
    end
    @cc = old_cc
    return h
  end

  def get_gene_locations
    #*--* locations GenboreeKB Place Holder
    #*--*-  location_id GenboreeKB Place Holder
    #*--*-- status  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/SequenceLocation/@Status
    #*--*-- chr //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/SequenceLocation/@Chr
    #*--*-- assembly //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/SequenceLocation/@Assembly
    #*--*-- accession //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/SequenceLocation/@Accession
    #*--*-- start //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/SequenceLocation/@start
    #*--*-- stop  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/SequenceLocation/@stop
    #*--*-- strand  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/SequenceLocation/@Strand
    r={
      'locations'=> []
    }
    references = get('./SequenceLocation')
    references.each do |s|
      @log.debug "location:#{s}"
      r['locations'] << {
        'location_id'=>{
          'status'=>get_doc_value(s,'./@Status'),
          'assembly'=>get_doc_value(s,'./@Assembly'),
          'chr'=>get_doc_value(s,'./@Chr'),
          'accession'=>get_doc_value(s,'./@Accession'),
          'start'=>get_doc_value(s,'./@start'),
          'stop'=>get_doc_value(s,'./@stop'),
          'strand'=>get_doc_value(s,'./@Strand'),
        }
      }
    end

    r['cytogenetic_location'] = get_value('./CytogeneticLocation')
    @log.debug r
    return r

  end

  def get_gene_cross_references
    #*--* cross_references  GenboreeKB Place Holder
    #*--*-  cross_reference_id  GenboreeKB Place Holder
    #*--*-- db_name //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/XRef/@DB
    #*--*-- db_id //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/XRef/@ID
    #*--*-- type  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/XRef/@Type
    r={
      'cross_reference'=> []
    }
    references = get('./MeasureRelationship[@Type="variant in gene"]/XRef')
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
    @log.debug r
    return r
  end

  def get_gene_comments
    #*--* comment GenboreeKB Place Holder
    #*--*-  comment_id  GenboreeKB Place Holder
    #*--*-- text  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/Comment
    #*--*-- data_source //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/Comment/@DataSource
    #*--*-- type  //ClinVarSet/ReferenceClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/Comment/@Type
    r={
      'comment'=> []
    }
    references = get('./MeasureRelationship[@Type="variant in gene"]/Comment')
    references.each do |s|
      @log.debug "reference:#{s}"
      r['comment'] << {
        'comment_id'=>{
          'text'=>get_doc_value(s,'.'),
          'data_source'=>get_doc_value(s,'./@DataSource'),
          'type'=>get_doc_value(s,'./@Type'),
        }
      }
    end
    @log.debug r

    return r
  end

  def get_diseases
    diseases = get('./ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]')
    h = {'diseases'=>[]}
    diseases.each do |allele|
      #*  diseases  GenboreeKB Place Holder
      #*- disease_id  GenboreeKB Place Holder
      #*-*  names GenboreeKB Place Holder
      #*-*- name_id GenboreeKB Place Holder
      #*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/ElementValue/@Type
      #*-*--  name  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/ElementValue
      #*-*-*  cross_references  GenboreeKB Place Holder
      #*-*-*- cross_reference_id  GenboreeKB Place Holder
      #*-*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/XRef/@DB
      #*-*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/XRef/@ID
      #*-*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/XRef/@Type
      r = get_disease_names
      #*-*  symbols GenboreeKB Place Holder
      #*-*- symbol_id GenboreeKB Place Holder
      #*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/ElementValue/@Type
      #*-*--  symbol  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/ElementValue
      #*-*-*  cross_references  GenboreeKB Place Holder
      #*-*-*- cross_reference_id  GenboreeKB Place Holder
      #*-*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/XRef/@DB
      #*-*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/XRef/@ID
      #*-*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/XRef/@Type
      r = get_disease_symbols.merge(r)
      #*-*  public_definitions  GenboreeKB Place Holder
      #*-*- public_definition_id  GenboreeKB Place Holder
      #*-*--  public_definition //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="public definition"]
      #*-*-*  cross_references  GenboreeKB Place Holder
      #*-*-*- cross_reference_id  GenboreeKB Place Holder
      #*-*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="public definition"]/following-sibling::XRef/@DB
      #*-*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="public definition"]/following-sibling::XRef/@ID
      #*-*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="public definition"]/following-sibling::XRef/@Type
      r = get_disease_public_definition.merge(r)
      #*-*  modes_of_inheritance  GenboreeKB Place Holder
      #*-*- mode_of_inheritance_id  GenboreeKB Place Holder
      #*-*--  mode_of_inheritance //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="ModeOfInheritance"]
      #*-*-*  cross_references  GenboreeKB Place Holder
      #*-*-*- cross_reference_id  GenboreeKB Place Holder
      #*-*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="ModeOfInheritance"]/following-sibling::XRef/@DB
      #*-*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="ModeOfInheritance"]/following-sibling::XRef/@ID
      #*-*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="ModeOfInheritance"]/following-sibling::XRef/@Type
      # get_disease_modes_of_inheritance
      #*-*  ages_of_onset GenboreeKB Place Holder
      #*-*- age_of_onset_id GenboreeKB Place Holder
      #*-*--  age_of_onset  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="age of onset"]
      #*-*-*  cross_references  GenboreeKB Place Holder
      #*-*-*- cross_reference_id  GenboreeKB Place Holder
      #*-*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="age of onset"]/following-sibling::XRef/@DB
      #*-*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="age of onset"]/following-sibling::XRef/@ID
      #*-*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="age of onset"]/following-sibling::XRef/@Type
      #  get_disease_ages_of_onset
      #*-*  mechanisms_of_disease GenboreeKB Place Holder
      #*-*- mechanism_of_disease_id GenboreeKB Place Holder
      #*-*--  mechanism_of_disease  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="disease mechanism"]
      #*-*-*  cross_references  GenboreeKB Place Holder
      #*-*-*- cross_reference_id  GenboreeKB Place Holder
      #*-*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="disease mechanism"]/following-sibling::XRef/@DB
      #*-*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="disease mechanism"]/following-sibling::XRef/@ID
      #*-*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="disease mechanism"]/following-sibling::XRef/@Type
      # get_disease_mechanisms
      #*-*  prevalance  GenboreeKB Place Holder
      #*-*- prevalance_id GenboreeKB Place Holder
      #*-*--  prevalance  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="prevalance"]
      #*-*-*  cross_references  GenboreeKB Place Holder
      #*-*-*- cross_reference_id  GenboreeKB Place Holder
      #*-*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="prevalance"]/following-sibling::XRef/@DB
      #*-*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="prevalance"]/following-sibling::XRef/@ID
      #*-*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="prevalance"]/following-sibling::XRef/@Type
      # get_disease_prevalance
      #*--* citations GenboreeKB Place Holder
      #*--*-  citation_id GenboreeKB Place Holder
      #*--*-- text  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Citation/@Abbrev
      #*--*-- type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Citation/@Type
      #*--*-- source  GenboreeKB Place Holder
      #*--*---  name  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Citation/ID/@Source
      #*--*---  id  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Citation/ID
      #*--*---  url //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Citation/URL
      # get_disease_citations
      h['diseases'] << {'disease_id'=>r}
    end
    return h
  end


  def get_reference(doc, ref_xpath)
    ref_sec_name = 'cross_reference'
    ref_sec_id = 'cross_reference_id'
    ref_path = ref_xpath
    r={
      ref_sec_name => []
    }
    @log.debug "reference not set here!"
    references = get(ref_path)
    references.each do |s|
      @log.debug "reference:#{s}"
      r[ref_sec_name] << {
        ref_sec_id=>{
          'db_name'=>get_doc_value(s,'./@DB'),
          'db_id'=>get_doc_value(s,'./@ID'),
          'type'=>get_doc_value(s,'./@Type'),
        }
      }
    end
    return r 
  end

  def get_disease_names
    #*  diseases  GenboreeKB Place Holder
    #*- disease_id  GenboreeKB Place Holder
    #*-*  names GenboreeKB Place Holder
    #*-*- name_id GenboreeKB Place Holder
    #*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/ElementValue/@Type
    #*-*--  name  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/ElementValue
    #*-*-*  cross_references  GenboreeKB Place Holder
    #*-*-*- cross_reference_id  GenboreeKB Place Holder
    #*-*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/XRef/@DB
    #*-*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/XRef/@ID
    #*-*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/XRef/@Type
    r={
      'names'=> []
    }
    # TODO: Assuming dealing with current clinvarset data
    names = get('./ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/ElementValue')
    names.each do |s|
      @log.debug "name:#{s}"
      r['names'] << {
        'name_id'=>{
          'name'=>get_doc_value(s,'.'),
          'type'=>get_doc_value(s,'./@Type'),
          #'cross_references'=>get_reference(@cc, './ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/XRef')
        }
      }
    end
    @log.debug r
    return r


  end

  def get_disease_symbols
    #*-*  symbols GenboreeKB Place Holder
    #*-*- symbol_id GenboreeKB Place Holder
    #*-*--  type  ./ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/ElementValue/@Type
    #*-*--  symbol  ./ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/ElementValue
    #*-*-*  cross_references  GenboreeKB Place Holder
    #*-*-*- cross_reference_id  GenboreeKB Place Holder
    #*-*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/XRef/@DB
    #*-*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/XRef/@ID
    #*-*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/XRef/@Type
    r={
      'symbols'=> []
    }
    names = get('./ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Symbol/ElementValue')
    names.each do |s|
      @log.debug "symbol:#{s}"
      r['symbols'] << {
        'symbol_id'=>{
          'symbol'=>get_doc_value(s,'.'),
          'type'=>get_doc_value(s,'./@Type'),
          #   'cross_references'=>get_reference(@cc, '//ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/XRef')
        }
      }
    end
    @log.debug r
    return r
  end


  def get_disease_public_definition
    #*-*  public_definitions  GenboreeKB Place Holder
    #*-*- public_definition_id  GenboreeKB Place Holder
    #*-*--  public_definition //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="public definition"]
    #*-*-*  cross_references  GenboreeKB Place Holder
    #*-*-*- cross_reference_id  GenboreeKB Place Holder
    #*-*-*--  db_name //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="public definition"]/following-sibling::XRef/@DB
    #*-*-*--  db_id //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="public definition"]/following-sibling::XRef/@ID
    #*-*-*--  type  //ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="public definition"]/following-sibling::XRef/@Type
    r={
      'public_definitions'=> []
    }
    names = get('./ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="public definition"]')
    names.each do |s|
      @log.debug "symbol:#{s}"
      r['public_definitions'] << {
        'public_definition_id'=>{
          'public_definition'=>get_doc_value(s,'.'),
          #  'cross_references'=>get_reference(@cc, '//ClinVarSet/ReferenceClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/AttributeSet/Attribute[@Type="public definition"]/following-sibling::XRef')
        }
      }
    end
    @log.debug r
    return r
  end

  def get_scvs
    scvs = get('./ClinVarAssertion')
    @log.debug "got #{scvs.length} scvs"
    h = {'clinvar_assertions'=>[]}
    scvs.each do |scv|
      @cc = XpathParser.new(scv) #TODO: This is really instrusive
      r = get_scv_submission_info
      @log.debug "after merging basic info:"+r.to_json
      r = get_scv_observations.merge(r)
      @log.debug "after merging observations:"+r.to_json
      r = get_scv_alleles.merge(r)
      @log.debug "after merging alleles:"+r.to_json
      r = get_scv_diseases.merge(r)
      @log.debug "after merging diseases:"+r.to_json
      h['clinvar_assertions'] << {'clinvar_assertion_id'=>r}
    end
    return h
  end

  def get_scv_submission_info
    # * clinvar_assertions  GenboreeKB Place Holder
    # *-  clinvar_assertion_id  GenboreeKB Place Holder
    # *-- submitter //ClinVarSet/ClinVarAssertion/ClinVarSubmissionID/@submitter
    # *-- title //ClinVarSet/ClinVarAssertion/ClinVarSubmissionID/@title
    # *-- submitter_date  //ClinVarSet/ClinVarAssertion/ClinVarSubmissionID/submitterDate
    # *-- clinvar_accession GenboreeKB Place Holder
    # *---  scv_accession //ClinVarSet/ClinVarAssertion/ClinVarSubmissionID/ClinVarAccession/@Acc
    # *---  version //ClinVarSet/ClinVarAssertion/ClinVarSubmissionID/ClinVarAccession/@Version
    # *---  org_id  //ClinVarSet/ClinVarAssertion/ClinVarSubmissionID/ClinVarAccession/@OrgID
    # *---  date_updated  //ClinVarSet/ClinVarAssertion/ClinVarSubmissionID/ClinVarAccession/@DateUpdated
    # *-- record_status //ClinVarSet/ClinVarAssertion/RecordStatus
    # *-- clinical_significance 
    # *---  date_last_evaluated //ClinVarSet/ClinVarAssertion/ClinicalSignificance/@DateLastEvaluated
    # *---  review_status //ClinVarSet/ClinVarAssertion/ClinicalSignificance/ReviewStatus
    # *---  assertion //ClinVarSet/ClinVarAssertion/ClinicalSignificance/Description
    # *-- assertion_type  //ClinVarSet/ClinVarAssertion/Assertion/@Type
    r = {}
    r['submitter'] = get_value('./ClinVarSubmissionID/@submitter')
    r['title'] = get_value('./ClinVarSubmissionID/@title')
    r['submitter_date'] = get_value('./ClinVarSubmissionID/@submitterDate')
    r['clinvar_accession'] = {}
    r['clinvar_accession']['scv_accession'] = get_value('./ClinVarAccession/@Acc')
    r['clinvar_accession']['version'] = get_value('./ClinVarAccession/@Version')
    r['clinvar_accession']['org_id'] = get_value('./ClinVarAccession/@OrgID')
    r['clinvar_accession']['date_updated'] = get_value('./ClinVarAccession/@DateUpdated')
    r['clinical_significance'] = {}
    r['clinical_significance']['date_last_evaluated'] = get_value('./ClinicalSignificance/@DateLastEvaluated')
    r['clinical_significance']['review_status'] = get_value('./ClinicalSignificance/ReviewStatus')
    r['clinical_significance']['assertion'] = get_value('./ClinicalSignificance/Description')
    r['assertion_type'] = get_value('./Assertion/@Type')
    r['record_status'] = get_value('./RecordStatus')
    @log.debug r
    return r
  end
  def get_scv_observations
    #*-* observations  GenboreeKB Place Holder
    #*-*-  sample_id GenboreeKB Place Holder
    #*-*-- origin  //ClinVarSet/ClinVarAssertion/ObservedIn/Sample/Origin
    #*-*-- species //ClinVarSet/ClinVarAssertion/ObservedIn/Sample/Species
    #*-*-- affected_status //ClinVarSet/ClinVarAssertion/ObservedIn/Sample/AffectedStatus
    #*-*-- number_tested //ClinVarSet/ClinVarAssertion/ObservedIn/Sample/NumberTested
    #*-*-- method_type //ClinVarSet/ClinVarAssertion/ObservedIn/Method/MethodType
    #*-*-- observed_data //ClinVarSet/ClinVarAssertion/ObservedIn/ObservedData
    r={
      'observations'=> []
    }
    names = get('./ObservedIn')
    names.each do |s|
      r['observations'] << {
        'sample_id'=>{
          'origin'=>get_doc_value(s,'./Sample/Origin'),
          'species'=>get_doc_value(s,'./Sample/Species'),
          'affected_status'=>get_doc_value(s,'./Sample/AffectedStatus'),
          'method_type'=>get_doc_value(s,'./Method/MethodType'),
          # 'observed_data'=>get_doc_value(s,'./ObservedData'), #TODO: This is perhaps an array!
          'number_tested'=>get_doc_value(s,'./Sample/NumberTested'),
        }
      }
    end
    @log.info "to be done!"
    @log.debug r
    return r

  end
  def get_scv_alleles
    #*-* alleles GenboreeKB Place Holder
    #*-*-  allele_id GenboreeKB Place Holder
    #*-*-- nucleotide_change //ClinVarSet/ClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[@Type = "nucleotide change"]
    #*-*-- gene  //ClinVarSet/ClinVarAssertion/MeasureSet/Measure/MeasureRelationship[@Type="variant in gene"]/Symbol/ElementValue[@Type="Preferred"]
    #*-*-* hgvs  GenboreeKB Place Holder
    #*-*-*-  hgvs_id GenboreeKB Place Holder
    #*-*-*-- type  //ClinVarSet/ClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[starts-with(@Type, 'HGVS')]/@Type
    #*-*-*-- value //ClinVarSet/ClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[starts-with(@Type, 'HGVS')]
    #*-*-- genbank_location  //ClinVarSet/ClinVarAssertion/MeasureSet/Measure/AttributeSet/Attribute[@Type = "Location"]
    r={
      'alleles'=> []
    }
    names = get('./MeasureSet/Measure')
    @log.debug "Got #{names.length} measures in scvs"
    names.each do |s|
      hgvs= get_by_doc(s, './AttributeSet/Attribute[starts-with(@Type, "HGVS")]')
      @log.debug "Got #{hgvs.length} hgvs names in scvs"
      n = []
      hgvs.each do |h|
        n << {
          'hgvs_id'=>{
            'type'=>get_doc_value(h,'./@Type'),
            'value'=>get_doc_value(h,'.')
          }
        }
      end
      r['alleles'] << {
        'allele_id'=>{
          'nucleotide_change'=>get_doc_value(s,'./AttributeSet/Attribute[@Type="nucleotide change"]'),
          'genbank_location'=>get_doc_value(s,'./AttributeSet/Attribute[@Type="Location"]'),
          'gene'=>get_doc_value(s,'./MeasureRelationship[@Type="variant in gene"]/Symbol/ElementValue[@Type="Preferred"]'),
          'hgvs'=>n
        }
      }
    end
    @log.debug r
    return r
    r = {}
  end
  def get_scv_diseases
    #*-* diseases  GenboreeKB Place Holder
    #*-*-  disease_id  GenboreeKB Place Holder
    #*-*-* names GenboreeKB Place Holder
    #*-*-*-  name_id GenboreeKB Place Holder
    #*-*-*-- type  //ClinVarSet/ClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/ElementValue/@Type
    #*-*-*-- name  //ClinVarSet/ClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/Name/ElementValue
    #*-*-*-* cross_reference GenboreeKB Place Holder
    #*-*-*-*-  cross_reference_id  GenboreeKB Place Holder
    #*-*-*-*-- db_name //ClinVarSet/ClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/XRef/@DB
    #*-*-*-*-- db_id //ClinVarSet/ClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/XRef/@ID
    #*-*-*-*-- type  //ClinVarSet/ClinVarAssertion/TraitSet[@Type="Disease"]/Trait[@Type="Disease"]/XRef/@Type
    r={
      'diseases'=> []
    }
    names = get('./TraitSet[@Type="Disease"]/Trait[@Type="Disease"]')
    @log.debug "Got #{names.length} diseases in scvs"
    names.each do |s|
      @log.debug s.inspect
      disease_names = get_by_doc(s, './Name')
      @log.debug "Got #{disease_names.length} disease names in scvs"
      n = []
      disease_names.each do |disease_name|
        n << {
          'name_id'=>{
            'type'=>get_doc_value(disease_name, './ElementValue/@Type'),
            'name'=>get_doc_value(disease_name, './ElementValue')
          }
        }
      end

      r['diseases'] << {
        'disease_id'=>{
          'names'=>n
        }
      }
    end
    @log.info "to be done!"
    @log.debug r
    return r
    r = {}
    {}
  end
  def print_stats
    print_log(@nil_log,"The following paths yielded nil values")
    print_log(@empty_log,"The following paths yielded empty values")
  end


  def save_json(j, file)
    File.open(file,'w') do |f|
      f.write(j)
    end
    @log.debug file+" saved for json:"
    @log.debug j
  end

  def to_kb_json(j)
    idAdder = AutoRandStrID.new()
    idAdder.setPreAndPostfix("snp", "id")
    to = JsonToKB.new("DocumentID", @id.to_s)
    @id += 1 
    idAdder.modifyIDs(to.to_kb(j)).to_json
  end

  private
  def record_nil_and_empty_xpath(v,xpath)
    if v.nil?
      @nil_log << xpath  
    elsif v.empty?
      @empty_log << xpath
    end
  end

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
    record_nil_and_empty_xpath(v,xpath)
    return v
  end

  def get_by_doc(doc, xpath)
    c = XpathParser.new(doc)
    v = c.get(xpath)
    record_nil_and_empty_xpath(v,xpath)
    return v
  end

  def get_array(xpath)
    v = @cc.get_content(xpath)
    record_nil_and_empty_xpath(v,xpath)
    return v
  end

  def get_doc_value(doc, xpath)
    c = XpathParser.new(doc)
    v = c.get_value(xpath)
    record_nil_and_empty_xpath(v,xpath)
    if v.nil?
      return ""
    end
    return v
  end

  def get_value(xpath)
    v = @cc.get_value(xpath)
    record_nil_and_empty_xpath(v,xpath)
    return v
  end

end
