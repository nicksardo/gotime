class window.GoTime
  @_syncCount: 0
  @_offset: 0
  @_precision: null
  @_lastSyncTime: null
  @_syncInterval: 900000
  @_synchronizing: false

  @_ajaxURL: null
  @_ajaxSampleSize: 1

  @_firstSyncCallbackRan: false
  @_firstSyncCallback: null
  @_onSyncCallback: null

  @_wsCall: null
  @_wsRequestTime: null

  constructor: () ->
    GoTime._setupSync
    return GoTime.now()


  @_setupSync: () =>
    if GoTime._synchronizing is false
      GoTime._synchronizing = true
      # Sync now
      GoTime._sync()
      # Sync in four seconds
      setTimeout(GoTime._sync, 4000);
      # Sync every quarter hour
      setInterval GoTime._sync, GoTime._syncInterval
    return

  # Public Getters
  @now: () =>
    new Date(Date.now() + @_offset)

  @getOffset: () =>
    @_offset

  @getPrecision: () =>
    @_precision

  # Setters
  @setAjaxURL = (url) =>
    @_ajaxURL = url
    GoTime._setupSync()

  # Callbacks
  @whenSynced: (callback) =>
    @_firstSyncCallback = callback

  @onSync: (callback) =>
    @_onSyncCallback = callback

  @wsSend: (callback) =>
    @_wsCall = callback

  @wsReceived: (serverTimeString) =>
    responseTime = Date.now()
    serverTime = GoTime._dateFromService serverTimeString
    sample = GoTime._calculateOffset @_wsRequestTime, responseTime, serverTime
    GoTime._reviseOffset sample


  # Private Methods
  @_ajaxSample = (i, callback) =>
    req = new XMLHttpRequest()
    req.open("GET", GoTime._ajaxURL);
    req.onreadystatechange = () ->
      responseTime = Date.now()
      if req.readyState is 4
        if req.status is 200
          serverTime = GoTime._dateFromService req.responseText
          sample = GoTime._calculateOffset requestTime, responseTime, serverTime
          GoTime._reviseOffset sample
          return

    requestTime = Date.now()
    req.send()
    return true

  @_sync: () =>
    if GoTime._wsCall?
      @_wsRequestTime = Date.now()
      success = GoTime._wsCall()
      if success
        @_syncCount++
        return
    if GoTime._ajaxURL?
      success = GoTime._ajaxSample 1
      if success
        @_syncCount++
        return


  @_calculateOffset: (requestTime, responseTime, serverTime) ->
    duration = responseTime - requestTime
    oneway = duration / 2
    return {
      offset: serverTime - requestTime + oneway
      precision: oneway
    }


  @_reviseOffset: (sample) =>
    if isNaN(sample.offset) or isNaN(sample.precision)
      return

    @_offset = sample.offset
    @_precision = sample.precision
    @_lastSyncTime = GoTime.now()

    if !@_firstSyncCallbackRan and @_firstSyncCallback?
      @_firstSyncCallbackRan = true
      @_firstSyncCallback()
    else if @_onSyncCallback?
      @_onSyncCallback()

  @_dateFromService: (text) =>
    return new Date(parseInt(text))

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


