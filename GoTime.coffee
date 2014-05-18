class window.GoTime
  @_offset: 0
  @_precision: null
  @_firstSyncCallbackRan: false
  @_lastSyncTime: null
  @_syncInterval: 600000
  @_ajaxSampleSize: 1
  @_synchronizing: false
  @_firstSyncCallback: null

  constructor: () ->
    if GoTime._synchronizing is false
      setInterval GoTime._sync, GoTime._syncInterval
      GoTime._synchronizing = true
      GoTime._sync()

    return GoTime.now()

  @now: () =>
    new Date(Date.now() + @_offset)


  @whenSynced: (callback) =>
    @_firstSyncCallback = callback

  @getOffset: () =>
    @_offset

  @_ajaxSample = (i, callback) ->
    req = new XMLHttpRequest()
    req.open("GET", '/time');
    req.onreadystatechange = () ->
      responseTime = Date.now()
      if req.readyState is 4                        # ReadyState Compelte
        if req.status is 200
          serverTime = new Date(parseInt(req.responseText)).getTime()
          sample = GoTime._calculateOffset requestTime, responseTime, serverTime
          callback i, sample
          return

    requestTime = Date.now();
    req.send()
    return null

  @_sync: () =>
    GoTime._ajaxSample 1, (i, sample) ->
      GoTime._reviseOffset sample

#    max = @ajaxSampleSize
#    samples = (sample num for num in [0..max])


    return

  @_calculateOffset: (requestTime, responseTime, serverTime) ->
    duration = responseTime - requestTime
    precision = duration / 2
    return {
      offset: serverTime + precision - responseTime
      precision: precision
    }


  @_reviseOffset: (sample) =>
    @_offset = sample.offset
    @_precision = sample.precision
    @_lastSyncTime = GoTime.now()

    if !@_firstSyncCallbackRan and @_firstSyncCallback?
      @_firstSyncCallback()
    else



#  @analyzeSamples: (samples) =>
#    totalPrecision = samples.reduce (sum, sample) ->
#        if sample?
#          return sum + sample.precision
#        else
#          return sum
#      , 0
#
#    totalWeight = 0
#    weightedSum = samples.reduce (sum, sample) ->
#        if sample?
#          weight = (totalPrecision / sample.precision)
#          totalWeight += weight
#          return sum + (sample.offset * weight)
#        else
#          return sum
#      , 0
#
#    @offset = weightedSum / totalWeight
#
#    console.log @offset.toFixed(0) + ' ' + totalPrecision.toFixed(0)
#    return


