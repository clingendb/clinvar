# Transform a tsv GenboreeKB document into a 
# special json file that clinvar xml parser needs
# @Author Xin Feng
# @Date 05/15/2015
# @Email xinf@bcm.edu
#


class  KBModelToClinVarParserJson

  def process(lines)
    r = {}
    puts lines.class
    puts lines.inspect
    if lines.length == 1
      puts "the last in the group."
      prefix,field,xpath = lines.first.split("\t")
      if prefix.end_with?('*')
        msg = "The last line within the group should not be a *"
        msg += "\nThe line is: \n"+root_line
        raise msg
      else prefix.end_with?('-')
        r[field]=xpath
      end
    else
      root_line = lines.shift
      puts "current root_line"+root_line
      raise_invalid(root_line)
      prefix,field,xpath = root_line.split("\t")

      puts "processing subgroups"
      if prefix.end_with?('*')
        puts "it's an array"
        next_line = lines.shift
        raise_invalid(next_line)

        prefix2,field2,xpath2 = next_line.split("\t")
        h = []
        groups = get_rootline_subgroups(next_line,lines)
        puts "got gropus:"+groups.size.to_s
        groups.each do |group|
          h << process(group)
        end
        r["#{field},#{field2},#{xpath}"] = h
      elsif prefix.end_with?('-')
        puts "it's a hash"
        h = {}
        groups = get_rootline_subgroups(root_line,lines)
        puts "got gropus:"+groups.size.to_s
        groups.each do |group|
          h = process(group).merge(h)
        end
        r["#{field},#{xpath}"] = h
      end
    end
    return r
  end

  def run(file)
    lines = IO.read(file).split("\n")
    process(lines)
  end

  def raise_invalid(line)
    toks = line.split("\t")
    if toks.length == 3 
      if toks[0].start_with?('*','-') and toks[0].end_with?('*','-')
        return true
      end
    end
    raise "Invalid line: \n"+root_line
  end

  def get_rootline_subgroups(root_line,sublines)
    prefix,field,xpath = root_line.split("\t")
    starting_length = prefix.length + 1
    puts "starting_length:#{starting_length}"
    groups = []
    current_group = []
    sublines.each do |line|
      raise_invalid(line)
      current_group << line

      prefix,field,xpath = line.split("\t")
      puts "prefix_length:#{prefix.length}"
      if prefix.length == starting_length
        groups << current_group
        current_group = []
      end
    end
    return groups
  end

  def process_root_line(root_line)
    prefix,field,xpath = root_line.split("\t")
    if prefix.end_with?('*')
      {"#{field},#{xpath}"=>[]}
    elsif prefix.end_with?('-')
      {"#{field},#{xpath}"=>{}}
    else
      raise "Unknown prefix char:"+prefix
    end
  end

  def ga
    lines.each_with_index do |line,ind|
      toks = line.split("\t")
      if toks.length < 2
        raise "Abnormal line at:#{@file.lineno}\n"+line
      end

      prefix = toks[0]
      if prefix.length < prefix_length  
        if lines_to_process.length < 1
          lines_to_process << line
        end

        if prefix.length == 1
          process lines_to_process
          lines_to_process = []
          lines_to_process << line
        else
          lines_to_process << line
        end

      end
    end

  end
  def transform(p)
    r= {}
    p.each {|key, value|
      if value.is_a?(Hash) 
        r[key] = {"value"=>""}
        r[key]["properties"] = transform(value) 
      elsif value.is_a?(Array)
        r[key] = {"items"=>[]}
        value.each_with_index do |v,ind|
          r[key]["items"] << transform(v)
        end
      else
        r[key] = {"value"=>value}
      end
    }
    return r 
  end

end
