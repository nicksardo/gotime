GoTime
======

Access the server's time from your browser with high precision
This project is used for chronograph.io, a website that syncs stopwatches across devices.  In order to synchronize the stopwatch actions (start/stop/split), GoTime provides the browser with a close estimate of the server's current time.

This project was built to be used by Go, but it can be used by any server-side language.  Just expose a web service that provides the current unix time (in milliseconds).

Setup
-----
1.  Expose your server's date through a webservice and/or websocket message. Further explained below.
2.  Include a link to GoTime.js in your html.  
      <script src="/js/GoTime.js"></script>
3.  Set the GoTime options in javascript to access either web service or websocket or both.
```javascript
  GoTime.setOptions({
    AjaxURL: "/time",
	SyncInitialTimeouts: [0,2000,5000,10000,50000, 55000], // First set of syncs (ms from initialization) [default]
    SyncInterval: 900000,       // Follow-up syncs happen at interval of 15 minutes [default]
    WhenSync: function() {
        console.log("Synced for first time")
    },
    OnSync: function(){
        console.log("Synced for second or higher time")
    }
  })

  GoTime.wsSend(function(){
		if (socket !== null && socket.readyState === 1) {
			sendEvent("time")
			return true // tell GoTime that websocket message was sent
		}
		return false // tell GoTime that websocket sending failed, try ajax webservice
	});


    ....
    // when processing websocket messages client-side
    // if response contains time, notify GoTime immediately with the data
    GoTime.wsReceived(msg.data)   // with msg.data = the unix (ms) time string

  
```

Exposing Server Time  
--------------------  
Chronograph.io syncs using an ajax call and websocket messages.  The reason is because the websocket connection may not be open in time for use.  Using just an ajax service is fine; however, you can get acheive more precise measurements by using websockets.  For a specific test of Chronograph.io, the initial ajax call resulted in a precision=78ms.  The next call using websockets acheived precision=11ms.

**Web Service**  
Simply a webservice that returns the server's unix (ms) time.  For go, see gotime.NowHandler or gotime.Now()


**Websocket**  
As shown in the setup portion, implementing the messaging is up to you, but you must provide GoTime with a callback that will send the time request and notify GoTime when the response arrives.


Usage After Setup  
-----------------  
At any time, you can call GoTime() to get a Date object.  However, GoTime might not have had a chance to sync yet, so either expect the internal clock offset to change.  
```javascript
var time = new GoTime();
// Mon May 19 2014 15:38:07 GMT-0700 (PDT)
or 
var time = GoTime.now()
// 1400539092790
```

You can also use these callbacks to wait until GoTime has synced.  
```javascript    
	// Calls a method after every sync, except for the first sync
	GoTime.onSync(updateClockStats);
	// After first sync, run this method
	GoTime.whenSynced(run)
```

**Internal Information**
```javascript
GoTime.getOffset()
```
// returns the difference between your clock and servertime.  Positive or negative

```javascript
GoTime.getPrecision()
```
// returns the number of milliseconds GoTime may differ from servertime.

```javascript
GoTime.getLastMethod()
```
// returns "ajax" or "websocket" for the last sync method

```javascript
GoTime.getSyncCount()
```
// returns amount of times GoTime has synced
