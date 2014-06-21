class window.GoTime
  @_syncCount: 0
  @_offset: 0
  @_precision: Infinity

  @_history: []

  @_syncInitialTimeouts: [0, 3000, 9000, 18000, 45000]
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

      # Initial syncs
      setTimeout(GoTime._sync, time) for time in GoTime._syncInitialTimeouts

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

  @getHistory: () =>
    @_history

  # Setters
  @setOptions = (options) =>
    if options.AjaxURL?
      @_ajaxURL = options.AjaxURL
    if options.SyncInitialTimeouts?
      @_syncInitialTimeouts = options.SyncInitialTimeouts
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
  @_ajaxSample: () =>
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
      success = GoTime._ajaxSample()
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

    now = GoTime.now()
    @_lastSyncTime = now
    @_lastSyncMethod = method

    # Add to history
    @_history.push(
      Sample: sample
      Method: method
      Time: now
    )

    # Only update the offset if the precision is improved
    if sample.precision <= @_precision
      @_offset = sample.offset
      @_precision = sample.precision

    # Callbacks
    if !@_firstSyncCallbackRan and @_firstSyncCallback?
      @_firstSyncCallbackRan = true
      @_firstSyncCallback(now, method, sample.offset, sample.precision)
    else if @_onSyncCallback?
      @_onSyncCallback(now, method, sample.offset, sample.precision)

  @_dateFromService: (text) =>
    return new Date(parseInt(text))


