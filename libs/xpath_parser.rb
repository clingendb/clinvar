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


  def self.open_with_nokogiri(file)
    f = File.open(file)
    o = Nokogiri::XML(f)
    f.close
    return o
  end

  def open_file file
    f = File.open(file)
    o = Nokogiri::XML(f)
    f.close
    set(o)
  end

  def read_string string
    o = Nokogiri::XML(string)
    set(o)
  end

  def initialize(nokogiri_object)
    @doc = nokogiri_object
    initiate_logger
  end
  
  def set(nokogiri_object)
    @doc = nokogiri_object
  end

  def get(xpath)
    @logger.debug xpath
    @doc.xpath(xpath).to_a
  end

  def get_content(xpath)
    ga = get(xpath)
    result = []
    ga.each do |node|
      result << node.content
    end
    return result
  end

  def get_value(xpath)
    ga = get(xpath)
    if ga.length > 1
      raise "The specified path:"+xpath+"\nreturns an array:"+ga.inspect
    elsif ga.length == 0
      return nil
    else
      return ga.first.content
    end
  end

  def sum(xpath)
    ga = get_content(xpath)
    s = 0
    ga.each do |g|
      s += g.to_i unless g.nil?
    end
    return s
 end

  private
  def initiate_logger
    @logger = Logging.logger(STDERR)
    @logger.level = :info
  end
end
