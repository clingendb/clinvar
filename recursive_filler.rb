require 'xpath_parser'

class RecursiveFiller

  def initialize
      @xml_parser = XpathParser.new(nil)
  end

  #{
  #  'names1,name_id1,xpath1' => [
  #    'names1_1,name_id1_1,xpath1_1'=>{...},
  #    'names1_2,name_id1_2,xpath1_2'=>[]
  #  ]
  #}

  #{
  #  'names1,name_id1,xpath1' => {
  #    'names1_1,name_id1_1,xpath1_1'=>{...},
  #    'names1_2,name_id1_2,xpath1_2'=>[]
  #  }
  #}
  #
  def get_xml
    n_xml = @xml_parser.get(@xpath)
    if n_xml.length > 1
      raise "Path:"+@xpath+"\n returns an array"
    elsif n_xml.length == 0
      #TODO: stats function goes here
      raise "Path:"+@xpath+"\n returns nothing"
    else
      return n_xml.first
    end
  end

  def fill(xml, p)
    r= {}
    puts "initial xml:"+xml.inspect
    @xml_parser = XpathParser.new(xml)

    p.each do |key, value|
      puts "key:"+key+"\nvalue:"+value.inspect
      if value.is_a?(Hash) 
        decode_hash_key(key) 
        puts "xpath in hash:"+@xpath
        r[@name] = fill(get_xml, value)
      elsif value.is_a?(Array)
        decode_array_key(key)
        r[@names] = []
        puts "xpath in array:"+@xpath
        docs = @xml_parser.get(@xpath)
        docs.each do |doc|
          rr = {}
          n_xml = get_xml
          value.each_with_index do |v,ind|
            rr = fill(n_xml,v).merge(rr)
          end
          r[@names] << {@name_id=>rr}
        end
      else
        r[key] = @xml_parser.get_value(value)
      end
    end
    return r 
  end

  def decode_array_key(key)
    @names,@name_id,@xpath = key.split(',')
  end

  def decode_hash_key(key)
    @name,@xpath = key.split(',')
  end
end
