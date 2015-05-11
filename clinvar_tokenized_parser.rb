# Test tokenizing clinvar xml
#
# @Author Xin Feng
# @Date 04/06/2015
#
#
#
require 'progressPrinter'
require 'logging'
require 'para_check'

ParaCheck.require(1, 'clinvar.file.xml')

    log = Logging.logger(STDERR)
    log.level = :info
file = File.open(ARGV[0],'rb')

fold = 5
buffer_size = 2**fold
clinvar_set_locs = []
#puts "buffer size:#{buffer_size}"
#(0..6).each do |i|
#  buffer = file.read(buffer_size)
#  puts "buffer being processed:\n"+buffer
#  break if buffer.nil?
#  loc = buffer.index(/<ClinVarSet/)
#  clinvar_set_locs << loc+(i*buffer_size) unless loc.nil?
#  puts "found a loc:"+loc.to_s unless loc.nil?
#  #file.seek(buffer_size, IO::SEEK_CUR)
#end


#file.rewind
#
#exit unless clinvar_set_locs.length > 1
#
##file.read(clinvar_set_locs.first)
#file.seek(clinvar_set_locs.first, IO::SEEK_CUR)
## for i in 1..(clinvar_set_locs.length - 1)
#for i in 1..4
#  buffer = file.read(clinvar_set_locs[i+1] - clinvar_set_locs[i])
#  puts "recalled buffer:\n"+buffer
#  file.seek(buffer.length, IO::SEEK_CUR)
#end
#
start_line_no =  []
end_line_no =  []
total_lines_cnt = 0
log.info "Finding locations of each set"
file.each_line do |line|
  total_lines_cnt += 1
  if line.include? '<ClinVarSet'
    start_line_no << file.lineno
  elsif line.include? 'ClinVarSet'
    end_line_no << file.lineno
  end
end
if start_line_no.length != end_line_no.length
raise "Incomplete clinvarset detected."
end
log.info "..Done"
log.info "Total lines in the xml file:#{total_lines_cnt}"
log.info "Total records in the xml file:#{start_line_no.length}"
dp = ProgressPrinter.new(start_line_no.length)
start_line_no.each_with_index do |l,ind|
  puts "#{l} - #{end_line_no[ind]}"
end
file.rewind

line_loc_ind = 0
line_cnt = 1
start_l_loc =  start_line_no[line_loc_ind]
end_l_loc =  end_line_no[line_loc_ind]
got_one = false
lines_buffer = ''
puts start_line_no.length
file.each_line do |line|
  if line_cnt >= start_l_loc && line_cnt <= end_l_loc 
    lines_buffer += line
  elsif line_cnt > end_l_loc
    line_loc_ind += 1
    if line_loc_ind >= start_line_no.length
      log.debug "Useful lines ends at #{end_l_loc}"
      exit
    end
    start_l_loc =  start_line_no[line_loc_ind]
    end_l_loc =  end_line_no[line_loc_ind]
    dp.printProgress($stderr, line_loc_ind)
    lines_buffer = ''
  end
  line_cnt += 1
end
puts lines_buffer
