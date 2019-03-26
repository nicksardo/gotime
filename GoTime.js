(function() {
  window.GoTime = (function() {
    class GoTime {
      constructor() {
        GoTime._setupSync();
        return new Date(GoTime.now());
      }

      static _setupSync() {
        var i, len, ref, time;
        if (GoTime._synchronizing === false) {
          GoTime._synchronizing = true;
          ref = GoTime._syncInitialTimeouts;
          for (i = 0, len = ref.length; i < len; i++) {
            time = ref[i];
            // Initial syncs
            setTimeout(GoTime._sync, time);
          }
          // Sync repetitively
          setInterval(GoTime._sync, GoTime._syncInterval);
        }
      }

      // Public Getters
      static now() {
        return Date.now() + GoTime._offset;
      }

      static getOffset() {
        return GoTime._offset;
      }

      static getPrecision() {
        return GoTime._precision;
      }

      static getLastMethod() {
        return GoTime._lastSyncMethod;
      }

      static getSyncCount() {
        return GoTime._syncCount;
      }

      static getHistory() {
        return GoTime._history;
      }

      // Setters
      static setOptions(options) {
        if (options.AjaxURL != null) {
          GoTime._ajaxURL = options.AjaxURL;
        }
        if (options.SyncInitialTimeouts != null) {
          GoTime._syncInitialTimeouts = options.SyncInitialTimeouts;
        }
        if (options.SyncInterval != null) {
          GoTime._syncInterval = options.SyncInterval;
        }
        if (options.OnSync != null) {
          GoTime._onSyncCallback = options.OnSync;
        }
        if (options.WhenSynced != null) {
          GoTime._firstSyncCallback = options.WhenSynced;
        }
        return GoTime._setupSync();
      }

      // Callbacks
      static wsSend(callback) {
        return GoTime._wsCall = callback;
      }

      static wsReceived(serverTimeString) {
        var responseTime, sample, serverTime;
        responseTime = Date.now();
        serverTime = GoTime._dateFromService(serverTimeString);
        sample = GoTime._calculateOffset(GoTime._wsRequestTime, responseTime, serverTime);
        return GoTime._reviseOffset(sample, "websocket");
      }

      // Private Methods
      static _ajaxSample() {
        var req, requestTime;
        req = new XMLHttpRequest();
        req.open("GET", GoTime._ajaxURL);
        req.onreadystatechange = function() {
          var responseTime, sample, serverTime;
          responseTime = Date.now();
          if (req.readyState === 4) {
            if (req.status === 200) {
              serverTime = GoTime._dateFromService(req.responseText);
              sample = GoTime._calculateOffset(requestTime, responseTime, serverTime);
              GoTime._reviseOffset(sample, "ajax");
            }
          }
        };
        requestTime = Date.now();
        req.send();
        return true;
      }

      static _sync() {
        var success;
        if (GoTime._wsCall != null) {
          GoTime._wsRequestTime = Date.now();
          success = GoTime._wsCall();
          if (success) {
            GoTime._syncCount++;
            return;
          }
        }
        if (GoTime._ajaxURL != null) {
          success = GoTime._ajaxSample();
          if (success) {
            GoTime._syncCount++;
          }
        }
      }

      static _calculateOffset(requestTime, responseTime, serverTime) {
        var duration, oneway;
        duration = responseTime - requestTime;
        oneway = duration / 2;
        return {
          offset: serverTime - requestTime - oneway,
          precision: oneway
        };
      }

      static _reviseOffset(sample, method) {
        var now;
        if (isNaN(sample.offset) || isNaN(sample.precision)) {
          return;
        }
        now = GoTime.now();
        GoTime._lastSyncTime = now;
        GoTime._lastSyncMethod = method;
        // Add to history
        GoTime._history.push({
          Sample: sample,
          Method: method,
          Time: now
        });
        // Only update the offset if the precision is improved
        if (sample.precision <= GoTime._precision) {
          GoTime._offset = Math.round(sample.offset);
          GoTime._precision = sample.precision;
        }
        if (!GoTime._firstSyncCallbackRan && (GoTime._firstSyncCallback != null)) {
          GoTime._firstSyncCallbackRan = true;
          return GoTime._firstSyncCallback(now, method, sample.offset, sample.precision);
        } else if (GoTime._onSyncCallback != null) {
          return GoTime._onSyncCallback(now, method, sample.offset, sample.precision);
        }
      }

      static _dateFromService(text) {
        return new Date(parseInt(text));
      }

    };

    GoTime._syncCount = 0;

    GoTime._offset = 0;

    GoTime._precision = 2e308;

    GoTime._history = [];

    GoTime._syncInitialTimeouts = [0, 3000, 9000, 18000, 45000];

    GoTime._syncInterval = 900000;

    GoTime._synchronizing = false;

    GoTime._lastSyncTime = null;

    GoTime._lastSyncMethod = null;

    GoTime._ajaxURL = null;

    GoTime._ajaxSampleSize = 1;

    GoTime._firstSyncCallbackRan = false;

    GoTime._firstSyncCallback = null;

    GoTime._onSyncCallback = null;

    GoTime._wsCall = null;

    GoTime._wsRequestTime = null;

    return GoTime;

  }).call(this);

}).call(this);
