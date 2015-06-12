# Upload a single doc
# @Author Xin Feng
# @Date 05/19/2015
# @Email xinf@bcm.edu
#

require 'rest'
require 'urlb'
require 'up'

class APIUploader

  def initialize()
    @code = 200
    @body = nil
    @url = nil
    @grpName = nil
    @kbName = nil
    @collName = nil
    @ready = false
  end

  def configure(group, kb, coll)
    @grpName = group
    @kbName = kb
    @collName = coll
    @ready = true
  end

  def set_resource_path(rsrc_path)
    @rsrcPath = "/REST/v1/grp/#{@grpName}/kb/#{@kbName}/coll/#{@collName}/#{rsrc_path}"
  end

  def setupURL

    @gbLogin, @usrPass = getUP 

    # Url building process
    @http     = 'http://'
    @genbHost = 'genboree.org'

    @propPath = '' 
    @detailed = '' 

    @url = buildURL(@genbHost, @gbLogin, @usrPass, @rsrcPath, @propPath, @detailed)

  end

  def upload(jsonBulk)
    raise "run setupAPI" unless @ready
    #raise "The input should be an array of Hash objs. Got #{jsonBulk.class}" unless jsonBulk.class == [].class

    setupURL

    @docSize  = jsonBulk.length
    @t1 = Time.now

    @code, @body = api_put_with_diag_quiet(@url, jsonBulk.to_json)

    @t2 = Time.now
  end

  def getUploadSpeed()
    puts @docSize
    @docSize / (@t2 - @t1 + 1 )
  end

  def uploadSuccessful?
    @code.to_i < 300
  end

  def serverMsg
    @body
  end

  def serverStatusMsg
    JSON.parse(@body)["status"]
  end

end
