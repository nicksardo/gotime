class window.GoTime
  @_syncCount: 0
  @_offset: 0
  @_precision: null

  @_syncSecondTimeout: 3000
  @_syncThirdTimeout: 6000
  @_syncInterval: 900000
  @_synchronizing: false
  @_lastSyncTime: null
  @_lastSyncMethod: null

  @_ajaxURL: null
  @_ajaxSampleSize: 1

  @_firstSyncCallbackRan: false
  @_firstSyncCallback: null
  @_onSyncCallback: null

  @_wsCall: null
  @_wsRequestTime: null

  constructor: () ->
    GoTime._setupSync()
    return new Date(GoTime.now())

  @_setupSync: () =>
    if GoTime._synchronizing is false
      GoTime._synchronizing = true
      # Sync now
      GoTime._sync()
      # Second Sync
      setTimeout(GoTime._sync, GoTime._syncSecondTimeout);
      # Third Sync
      setTimeout(GoTime._sync, GoTime._syncThirdTimeout);
      # Sync repetitively
      setInterval GoTime._sync, GoTime._syncInterval
    return

  # Public Getters
  @now: () =>
    Date.now() + @_offset

  @getOffset: () =>
    @_offset

  @getPrecision: () =>
    @_precision

  @getLastMethod: () =>
    @_lastSyncMethod

  @getSyncCount: () =>
    @_syncCount

  # Setters
  @setOptions = (options) =>
    if options.AjaxURL?
      @_ajaxURL = options.AjaxURL
    if options.SyncSecondTimeout?
      @_syncSecondTimeout = options.SyncSecondTimeout
    if options.SyncSecondTimeout?
      @_syncThirdTimeout = options.SyncThirdTimeout
    if options.SyncInterval?
      @_syncInterval = options.SyncInterval

    if options.OnSync?
      @_onSyncCallback = options.OnSync
    if options.WhenSynced?
      @_firstSyncCallback = options.WhenSynced

    GoTime._setupSync()

  # Callbacks
  @wsSend: (callback) =>
    @_wsCall = callback

  @wsReceived: (serverTimeString) =>
    responseTime = Date.now()
    serverTime = GoTime._dateFromService serverTimeString
    sample = GoTime._calculateOffset @_wsRequestTime, responseTime, serverTime
    GoTime._reviseOffset sample, "websocket"


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
          GoTime._reviseOffset sample, "ajax"
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


  @_reviseOffset: (sample, method) =>
    if isNaN(sample.offset) or isNaN(sample.precision)
      return

    @_offset = sample.offset
    @_precision = sample.precision
    @_lastSyncTime = GoTime.now()
    @_lastSyncMethod = method

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


