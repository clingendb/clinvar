# Tokenized uploader for clinvar xml
#
# @Author Xin Feng
# @Date 05/19/2015
#
#
#
require 'progressPrinter'
require 'logging'
require 'nokogiri'
require 'recursive_filler'
require 'auto_rand_str_id'
require 'json_to_kb'
require 'remove_empty_and_nil'
require 'api_uploader'
require 'json'

class ClinVarXMLTokenizedUploader
  def initialize(clinvar_xml_file, model_json)
    @file = File.open(clinvar_xml_file,'rb')
    @h = JSON.parse(File.read(model_json))
    @log = Logging.logger[self]
    @log.level = :info
    @clinvar_set_locs = []
    @start_line_no =  []
    @end_line_no =  []
    @total_lines_cnt = 0
    @clinvar_set_ids = []
    @KEY1 = '<ClinVarSet'
    @KEY2 = '/ClinVarSet'
    @lines_buffer = ''
    @id = 1
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

  def configure_api(group,kb,coll)
    @group = group
    @kb = kb
    @coll = coll
    @api_ready = true
  end

  def parse str
    xml = Nokogiri::XML(str)
    filler = RecursiveFiller.new()
    ga = JsonToKB.new('DocumentID',@id)
    id_adder = AutoRandStrID.new()
    puts "TODO: Fix this post and prefix"
    id_adder.setPreAndPostfix('snp','id')
    uploader = APIUploader.new()
    raise "Call configure_api first" unless @api_ready
    uploader.configure(@group,@kb,@coll)
    uploader.set_resource_path("doc/#{@id}?")
    hash = filler.fill(xml,@h)['DocumentID']
    filler.report_nil_and_empty_paths
    json= id_adder.modifyIDs(ga.to_kb(hash))
    json = RemoveEmptyAndNilKB.process(json)
    @log.debug "json to be uploaded:\n"+json.to_json
    uploader.upload(json)
    @log.debug uploader.serverStatusMsg
    if not uploader.uploadSuccessful?
      @log.warn "Upload failed" if uploader.uploadSuccessful?
      @log.warn uploader.serverMsg
    end
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
end
