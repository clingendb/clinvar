require 'xpath_parser'
require 'logging'
class RecursiveFiller

  def initialize(delim=',,,')
    @xml_parser = XpathParser.new(nil)
    @delim = delim #TODO Decided in the model transformer
    @nil_log= []
    @empty_log= []
    @log = Logging.logger[self]
    @log.level = :info
  end

  # ********************************
  # Example format of the input data structure

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
    p.each do |key, value|
      if value.is_a?(Hash) 
        decode_hash_key(key) 
        @xml_parser.set(xml)
        n_xml = get_xml
        # puts "\nHash xml:"+xml.inspect+"\nkey:"+key+"\nvalue:"+value.inspect+"\nn_xml"+n_xml.inspect
        if n_xml.nil?
          @nil_log<< {'xml'=>xml,'path'=>@xpath}
        elsif n_xml.length > 1
          # This means you have a bug in your model
          raise "Path:"+xpath+"\n returns an array. Your model has a bug here."
        elsif n_xml.length == 0
          @empty_log << {'xml'=>xml,'path'=>@xpath}
        else
          r[@name] = fill(n_xml.first, value)
        end
      elsif value.is_a?(Array)
        @xml_parser.set(xml)
        decode_array_key(key)
        docs = @xml_parser.get(@xpath)
        # puts "\nArray xml:"+xml.inspect+"\nkey:"+key+"\nvalue:"+value.inspect+"\nn_xml"+docs.inspect
        if docs.nil?
          @nil_log<< {'xml'=>xml,'path'=>@xpath}
        elsif docs.length > 0
          r[@names] = []
          docs.each do |doc|
            rr = {}
            value.each_with_index do |v,ind|
              rr = fill(doc,v).merge(rr)
            end
            decode_array_key(key) # restore member variables
            r[@names] << {@name_id=>rr}
          end
        else 
        # Dont do anything if docs is empty
          @empty_log << {'xml'=>xml,'path'=>@xpath}
        end
      else
        @xml_parser.set(xml)
        doc = @xml_parser.get(value)
        # puts "\nSimple xml:"+xml.inspect+"\nkey:"+key+"\nvalue:"+value.inspect+"\nn_xml"+doc.inspect
        if doc.nil?
          @nil_log<< {'xml'=>xml,'path'=>value}
        elsif doc.length > 1
          # This means you have a bug in your model
          raise "Path:"+xpath+"\n returns an array. Your model has a bug here."
        elsif doc.length == 0
          @empty_log << {'xml'=>xml,'path'=>value}
        else
          r[key] = doc.first.content
        end
      end
    end
    return r 
  end

  def report_nil_and_empty_paths
    print_stats
  end
  private
  def get_xml
    xpath = @xpath
    raise '@xpath is nil' if xpath.nil?
    n_xml = @xml_parser.get(xpath)
    return n_xml
  end

  def decode_array_key(key)
    @names,@name_id,@xpath = key.split(@delim)
  end

  def decode_hash_key(key)
    @name,@xpath = key.split(@delim)
  end

  private
  def print_stats
    print_log(@nil_log,"The following paths yielded nil values")
    print_log(@empty_log,"The following paths yielded empty values")
  end

  def print_log(val,msg="")
    if val.length > 0
      @log.info msg 
      val.each do |v|
        @log.info v['path'].inspect+"\n"+v['xml'].inspect+"\n"
      end
    end
  end
end
