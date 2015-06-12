
class ProgressPrinter

  def initialize(size)
    setTotal(size)
    @old_per = 0
    @per = 0
  end

  def _updateCounter
    @old_per = @per
  end

  def _calculateProgress(cnt)
    @per = (cnt) *100/@size
  end

  def setTotal(size)
    @size = size
    # implicitly the user may mean this
    @old_per = 0
    @per = 0
  end

  def printProgress(stream, count)
    _calculateProgress(count)
    if (_reachesPrintCutoff())
      stream.puts "#{@per}%"
    end
    _updateCounter()
  end

  def get_progress(stream, count)
    _calculateProgress(count)
    if (_reachesPrintCutoff())
      return "#{@per}%"
    end
    _updateCounter()
  end

  def _reachesPrintCutoff()
     ((@per % 10) == 0 || (@per % 5) == 0) && @per != @old_per
  end

end
