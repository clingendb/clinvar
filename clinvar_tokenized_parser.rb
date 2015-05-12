# Tokenized parser for clinvar xml
#
# @Author Xin Feng
# @Date 05/11/2015
#
#
#
require_relative 'clinvar_xml_parser'
require 'progressPrinter'
require 'logging'
require 'nokogiri'

class ClinVarXMLTokenizedParser
  def initialize(file)
    @file = File.open(file,'rb')
    @log = Logging.logger(STDERR)
    @log.level = :debug
    @clinvar_set_locs = []
    @start_line_no =  []
    @end_line_no =  []
    @total_lines_cnt = 0
    @clinvar_set_ids = []
    @KEY1 = '<ClinVarSet'
    @KEY2 = '/ClinVarSet'
    @lines_buffer = ''
  end

  def get_clinvar_set_locs_and_ids
    @file.each_line do |line|
      @total_lines_cnt += 1
      if line.include? @KEY1
        @start_line_no << @file.lineno
        @clinvar_set_ids << line.match(/<ClinVarSet ID=(.*)>/)[0]
      elsif line.include? @KEY2
        @end_line_no << @file.lineno
      end
    end
    if @start_line_no.length != @end_line_no.length
      raise "Incomplete clinvarset detected."
    end
    @file.rewind
  end

  def parse str
    pp = ClinVarXMLParser.new(Nokogiri::XML(str))#TODO: should be moved into CLinVarxmlparser
    pp.run
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
end
