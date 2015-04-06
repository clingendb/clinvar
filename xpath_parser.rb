#
# @Author Xin Feng
# @Date 04/06/2015
#
#
#
require 'nokogiri'
require 'progressPrinter'
require 'logging'

class XpathParser

  def initiate(file)
    @file  = file
    initiate_logger
    parse_xml
  end

  def parse_xml
    f = File.open(@file)
    @doc = Nokogiri::XML(f)
    f.close
    @logger.debug 'File parsing complete'
  end

  def initiate_logger
    @logger = Logging.logger(STDERR)
    @logger.level = :debug
  end

  def get(xpath)
    @doc.xpath(xpath)
  end
end
