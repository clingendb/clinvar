# @Author Xin Feng
# @Date 04/06/2015
# @Email xinf@bcm.edu
#
#
#
require 'minitest/autorun'
require_relative './xpath_parser'

class XpathParserTest< Minitest::Test

  def setup
    file = './RCV000077146.xml'
    pp = XpathParser.new(file)
  end

  def test_invalid_path
      nul_val = pp.get('wrong_path')
      assert_equal nil, nul_val
  end

  def test_simple_value
    title = pp.get('//ClinVarSet/Title')
    transcript = title.split(':')[0]
    assert_equal 'NM_007294.3(BRCA1)' , transcript
  end

  def test_array_value
    origins = pp.get('//ClinVarSet/ReferenceClinVarAssertion/ObservedIn/Sample/Origin')
    assert_equal 2, origins.length 
  end
end
