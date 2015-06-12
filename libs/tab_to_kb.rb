# Transform a tab file to a KB doc
# @Author Xin Feng
# @Date 02/11/2015
# @Email xinf@bcm.edu
#

require 'json'
require 'json_to_kb'

class  TabToKB

  def initialize(rootIDName, headerFile)
    @id = 1
    @jtk = JsonToKB.new(rootIDName,@id)
    @root = rootIDName
    @h = {}
    @gotHead = false
    @toks = []
    @header = headerFile
    @headerFields = []
  end

  def transform(fileName)
    setupFields() if needHeader?
    File.open(fileName, "rb").each do |l|
      parseLine(l)
      buildLineHash()
      serializeLine(fileName)
    end
  end

  private

  def parseLine(l)
    @toks = l.split("\t") 
    removeTrailingNewLine()
    raiseInvalidLine(l) unless needHeader?
  end

  def removeTrailingNewLine()
    @toks[-1] = @toks[-1].sub("\n","")
  end

  def raiseInvalidLine(l)
    msg ="Invalid line: \n#{l}"
    msg += "\nYour header line has #{@headerFields.length} elements"
    msg += "\nBut the line has #{@toks.length} elements"
    raise msg unless @headerFields.length == @toks.length
  end

  def needHeader?()
    not @gotHead
  end

  def buildLineHash()
    @headerFields.each_with_index do |f,ind|
      @h[f]=@toks[ind]
    end
  end

  def setupFields()
    File.open(@header, "rb").each do |l|
      parseLine(l)
      raise "Is the file delimited by tab?" unless @toks.length > 2
      @headerFields = @toks
      @gotHead = true
      break
    end
  end

  def serializeLine(fileName)
    File.open(fileName+@id.to_s+".json","wb") do |f|
      @jtk.id(@id)
      @id += 1
      f.write(@jtk.to_kb_json(@h))
    end
  end
end
