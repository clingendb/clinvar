require 'xpath_parser'

class RecursiveFiller

  def initialize
      @xml_parser = XpathParser.new(nil)
  end

  #{
  #  'names1,name_id1,xpath1' => [
  #    'name1_1,xpath1_1'=>{...},
  #    'names1_22,name_id1_2,xpath1_2'=>[]
  #  ]
  #}

  #{
  #  'names1,name_id1,xpath1' => {
  #    'name1_1,xpath1_1'=>{...},
  #    'names1_2,name_id1_2,xpath1_2'=>[]
  #  }
  #}
  #

  #{
  #  'name1' => xpath
  #}
  #

  def fill(xml, p)
    r= {}
    puts "initial xml:"+xml.inspect
    @xml_parser = XpathParser.new(xml)

    p.each do |key, value|
      puts "key:"+key.inspect+"\nvalue:"+value.inspect
      if value.is_a?(Hash) 
        puts "key in hash:"+key
        decode_hash_key(key) 
        puts "xpath in hash:"+@xpath
        r[@name] = fill(get_xml, value)
      elsif value.is_a?(Array)
        puts "key in array:"+key
        decode_array_key(key)
        r[@names] = []
        puts @names+" initizted current r:"+r.inspect
        puts "xpath in array:"+@xpath
        docs = @xml_parser.get(@xpath)
        puts "docs.length in array:"+docs.length.to_s
        docs.each do |doc|
          rr = {}
          puts "GA"
          value.each_with_index do |v,ind|
            rr = fill(doc,v).merge(rr)
            decode_array_key(key) # restore member variables
          end
          puts "@names #{@names} rr:"+rr.inspect
          puts "current r"+r.inspect
          if r[@names].nil?
          puts "r[@names] #{r[@names]}"
          puts "@names #{@names}"
          puts "current r"+r.inspect

          end
          r[@names] << {@name_id=>rr}
        end
      else
        puts "just get the value"
        r[key] = @xml_parser.get_value(value)
      end
    end
    puts "done:"+r.inspect
    return r 
  end

  private
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

  def decode_array_key(key)
    @names,@name_id,@xpath = key.split(',')
  end

  def decode_hash_key(key)
    @name,@xpath = key.split(',')
  end
end
