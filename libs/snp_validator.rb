# Validate SNPs
#
# @Author Xin Feng
# @Date 02/24/2015
# @Email xinf@bcm.edu

class SNPValidator

  def isValidAllele(allele)
      not (notATGC?(allele) or longerThan1(allele))
  end

  def notATGC?(allele)
    /[ATGC]/.match(allele).nil?
  end

  def longerThan1(allele)
    allele.length > 1
  end

end
