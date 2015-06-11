# Get an element of clinvar xml
#
# @Author Xin Feng
# @Date 05/12/2015
#
#
#
require_relative 'clinvar_tokenized_parser'
require 'progressPrinter'
require 'logging'

class ClinVarXMLTokenizedExtractor << ClinVarTokenizedParser
  def initialize(file, id)
    super(file)
    @id = id
  end

  def parse str
    puts @lines_buffer
  end

  def find_ind 
    @clinvar_set_ids.each_with_index do |id,ind|
      if id.include? @id
        return ind
      end
    end
    return nil
  end

  def run
    @log.info "Finding locations of each set"
    get_clinvar_set_locs_and_ids
    @log.info "..Done"
    @log.info "Total lines in the xml file:#{@total_lines_cnt}"
    @log.info "Total records in the xml file:#{@start_line_no.length}"
    dp = ProgressPrinter.new(@start_line_no.length)

    ind = find_ind 
    raise "Didnt find your id" if ind.nil?
    line_loc_ind = 0
    line_cnt = 1
    start_l_loc =  @start_line_no[ind]
    end_l_loc =  @end_line_no[ind]

    @file.each_line do |line|
      if line_cnt >= start_l_loc && line_cnt <= end_l_loc 
        @lines_buffer += line
      elsif line_cnt > end_l_loc
        parse @lines_buffer
        return
      end
      line_cnt += 1
    end
    
    parse @lines_buffer

  end
end
