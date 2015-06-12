# Transform a tsv GenboreeKB document into a 
# special json file that clinvar xml parser needs
# @Author Xin Feng
# @Date 05/15/2015
# @Email xinf@bcm.edu
#


class  KBModelToClinVarParserJson

  def initialize
    @delim = ',,,'
  end

  def run(file)
    lines = IO.read(file).split("\n")
    lines.delete_if do |line|
      line.start_with?('#')
    end
    return process_root(lines)
  end

  private

  def process_root(lines)
    r = {}
    root_line = lines.shift
    prefix,field,xpath = root_line.split("\t")
    root_groups = find_root_groups(lines)
    root_groups.each do |root_group|
      r = process(root_group).merge(r)
    end
    return {"#{field}#{@delim}#{xpath}"=>r}
  end

  def find_root_groups(sublines)
    get_rootline_subgroups(0,sublines)
  end

  def process(lines)
    r = {}
    if lines.length == 1
      root_line = lines.first
      prefix,field,xpath = root_line.split("\t")
      if prefix.end_with?('*')
        msg = "The last line within the group should not be a *"
        msg += "\nThe line is: \n"+root_line
        raise msg
      else prefix.end_with?('-')
        r[field]=xpath
      end
    else
      root_line = lines.shift
      raise_invalid(root_line)
      prefix,field,xpath = root_line.split("\t")

      if prefix.end_with?('*')
        next_line = lines.shift
        raise_invalid(next_line)

        prefix2,field2,xpath2 = next_line.split("\t")
        h = []
        groups = get_rootline_subgroups(prefix2.length,lines)
        groups.each do |group|
          h << process(group)
        end
        r["#{field}#{@delim}#{field2}#{@delim}#{xpath}"] = h
      elsif prefix.end_with?('-')
        h = {}
        groups = get_rootline_subgroups(prefix.length,lines)
        groups.each do |group|
          h = process(group).merge(h)
        end
        r["#{field}#{@delim}#{xpath}"] = h
      end
    end
    return r
  end

  def get_rootline_subgroups(root_line_prefix_length,sublines)
    starting_length = root_line_prefix_length+ 1
    groups = []
    current_group = []
    sublines.each do |line|
      raise_invalid(line)
      prefix,field,xpath = line.split("\t")
      if prefix.length == starting_length && current_group == []
        current_group << line
      elsif prefix.length == starting_length && current_group != []
        groups << current_group
        current_group = []
        current_group << line
      elsif prefix.length != starting_length && current_group != []
        current_group << line
      elsif prefix.length != starting_length && current_group == []
        raise "Error found in the doc file at line\n"+line
      end
    end
    groups << current_group
    return groups
  end

  def raise_invalid(line)
    toks = line.split("\t")
    if toks.length >= 3 
      if toks[0].start_with?('*','-') and toks[0].end_with?('*','-')
        return true
      end
    end
    raise "Invalid line: \n"+line
  end

end
