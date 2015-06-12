# Tokenize a line and returns an array of tokens
#
# @Author Xin Feng
# @Date 02/24/2015
# @Email xinf@bcm.edu

require 'json_to_kb'
require 'auto_rand_str_id'
require 'json'
require 'progressPrinter'
require 'snp_validator'


class LineTokenizerByColumn

  def initialize(file)
    @mainFile = file
    @id = 0
  end

  def doit()
    @t1 = Time.now()
    bigResult = []
    result= {"snps"=>[]}
    cnt = 0
    partCnt = 0
    partFileCnt = 0

    $stderr.puts "Reading File"
    lines = IO.readlines(@mainFile,"\n")
    @totalSize = lines.length
    $stderr.puts "File reading done. Got #{@totalSize} lines"
    dp = ProgressPrinter.new(@totalSize)

    lines.each do |l|
      r = buildJsonHash(parseLineForElements(l))
      next if r == {}
      partCnt += 1
      partFileCnt += 1

      result["snps"] << r
      cnt = cnt + 1
      # break if cnt == 2

      dp.printProgress($stderr,cnt)

      if partCnt == @batchSize
        bigResult << to_kb(result)
        partCnt = 0
        result= {"snps"=>[]}
      end
    end


    bigResult << to_kb(result)
    @partSize = (bigResult.length* @batchPercent).to_i + 1
    $stderr.puts "The size of the big array:#{bigResult.length}"
    $stderr.puts "Each output part's size is #{@partSize}"
    bigResult.each_slice(@partSize) do |slice|
      @id += 1
      dumpJsonArray(slice)
      $stderr.puts "Saved 1 file:#{@id}"
    end

    @t2 = Time.now()
  end

  def batchSize(size)
    @batchSize = 1000
  end

  def printJobInfo()
    $stderr.puts "The original file is "+@mainFile
    $stderr.puts "Each file is saved as #{@resultPrefix}_X.json"
  end

  def printPerformanceData()
    $stderr.puts "The file is splitted into #{@id} pieces"
    $stderr.puts "Total time:#{@t2-@t1}"
  end

  def resultFilePercent(per)
    @batchPercent = per
  end

  def resultFilePrefix(s)
    @resultPrefix = s
  end

  private

  def to_kb(hash)
    to = JsonToKB.new("DocumentID",@id.to_s)
    idAdder = AutoRandStrID.new()
    idAdder.setPreAndPostfix("snp","id")
    idAdder.modifyIDs(to.to_kb(hash))
  end

  def dumpJsonArray(array)
    File.open(@resultPrefix+"_#{@id - 1}.json","wb") do |f|
      f.write(array.to_json)
    end
  end

  def isValidSNP(ref, alt)
    v = SNPValidator.new()
    v.isValidAllele(ref) and v.isValidAllele(alt)
  end

  def parseLineForElements line
    toks = line.split("\t")
    if toks.length == 6
      chr = toks[0]
      start = toks[1]
      ref = toks[2]
      alt = toks[3]
      freq = toks[4]
      rsID = toks[5].sub("\n","")
      if isValidSNP(ref, alt)
        return chr, start, ref, alt, freq, rsID
      end
    end
    nil
  end

  def buildJsonHash toks
    return {} if toks.nil?
    if toks.length == 6
      chr = toks[0]
      start = toks[1]
      ref = toks[2]
      alt = toks[3]
      freq = toks[4]
      rsID = toks[5]
      return {"snpID"=>{"chr"=>chr,"start"=>start,"refAllele"=>ref,
                        "altAllele"=>alt,"frequency"=>freq,"rsID"=>rsID}}
    end
    return {}
  end

end
