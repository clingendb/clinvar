# Tokenized uploader for clinvar xml
# that stores results to file
# @Author Xin Feng
# @Date 05/19/2015
#
#
#
require_relative 'clinvar_tokenized_uploader'
require 'logging'
require 'nokogiri'
require 'recursive_filler'
require 'auto_rand_str_id'
require 'json_to_kb'
require 'remove_empty_and_nil'
require 'json'

class ClinVarXMLTokenizedUploaderToFile < ClinVarXMLTokenizedUploader
  def initialize(clinvar_xml_file, model_json)
    super(clinvar_xml_file, model_json)
    @filename = clinvar_xml_file
    @id = 1
    @jsons = []
    @result_file_id = 0
  end

  def set_buffer_size(size)
    @buffer_size = size
  end

  def parse str
    determine_buffer_size

    xml = Nokogiri::XML(str)
    filler = RecursiveFiller.new()
    puts "TODO: Fix these constants"
    ga = JsonToKB.new('DocumentID',@id)
    id_adder = AutoRandStrID.new()
    id_adder.setPreAndPostfix('snp','id')
    hash = filler.fill(xml,@h)['DocumentID']
    filler.report_nil_and_empty_paths
    puts "TODO: Fix this part"
    hash['observations'].each do |ar|
      ar['sample_id']['number_of_observations'] = 0
    end
    json= id_adder.modifyIDs(ga.to_kb(hash))
    json = RemoveEmptyAndNilKB.process(json)
    @jsons << json
    output_json_if_reach_size_limit
    @id += 1
  end

  def run
    @log.info "Finding locations of each set"
    get_clinvar_set_locs_and_ids
    @log.info "..Done"
    @log.info "Total lines in the xml file:#{@total_lines_cnt}"
    @log.info "Total records in the xml file:#{@start_line_no.length}"
    dp = ProgressPrinter.new(@start_line_no.length)

    line_loc_ind = 0
    line_cnt = 1
    start_l_loc =  @start_line_no[line_loc_ind]
    end_l_loc =  @end_line_no[line_loc_ind]

    @file.each_line do |line|
      if line_cnt >= start_l_loc && line_cnt <= end_l_loc 
        @lines_buffer += line
      elsif line_cnt > end_l_loc
        line_loc_ind += 1
        if line_loc_ind >= @start_line_no.length
          @log.debug "Useful lines ends at #{end_l_loc}"
          break
        end
        start_l_loc =  @start_line_no[line_loc_ind]
        end_l_loc =  @end_line_no[line_loc_ind]
        @log.info "Progress: #{dp.get_progress($stderr, line_loc_ind)}%"
        @log.warn "Parsing clinvarset: #{@clinvar_set_ids[line_loc_ind - 1]}"
        parse @lines_buffer
        @lines_buffer = ''
      end
      line_cnt += 1
    end

    parse @lines_buffer

  end
  private
  def determine_buffer_size
    total_records = @clinvar_set_ids.length
    @buffer_size = total_records / 5
  end

  def getNextResultFileName
    @result_file_id += 1
    "#{@filename}_#{@result_file_id}.json"
  end

  def  output_json_if_reach_size_limit
    if @jsons.length > @buffer_size
      fileName = getNextResultFileName
      @log.info "Saved #{@jsons.length} docs into "+fileName
      File.open(fileName, "wb") do |f|
        f.write(@jsons.to_json)
      end
      @jsons = []
    end
  end

end
