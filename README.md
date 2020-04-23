GoTime
======

GoTime provides a browser client with a close approximation of the server's current time.

This project was built to be used by Go, but it can be used by any server-side language. Just expose a web service that provides the current unix time (in milliseconds).

Setup
-----
1.  Expose your server's date through a webservice and/or websocket message. Further explained below.
2.  Include a link to GoTime.js in your html.  
      <script src="/js/GoTime.js"></script>
3.  Set the GoTime options in javascript to access either web service or websocket or both.
```javascript
  GoTime.setOptions({
    AjaxURL: "/time",
	SyncInitialTimeouts: [0, 3000, 9000, 18000, 45000], // First set of syncs (ms from initialization) [default]
    SyncInterval: 900000,       // Follow-up syncs happen at interval of 15 minutes [default]
    WhenSynced: function(time, method, offset, precision) {
        console.log("Synced for first time")
    },
    OnSync: function(time, method, offset, precision){
        console.log("Synced for second or higher time")
    }
  })

  //Give GoTime a function that will send a websocket message to get the server time
  GoTime.wsSend(function(){
		if (socket !== null && socket.readyState === 1) {
			sendEvent("time")
			return true // tell GoTime that websocket message was sent
		}
		return false // tell GoTime that websocket sending failed, try ajax webservice
  });


    ....
    // When processing websocket messages client-side
    // If response is the server telling the time, notify GoTime immediately with the data
    GoTime.wsReceived(msg.data)   // with msg.data = the unix (ms) time string

  
```

Exposing Server Time  
--------------------  
The page syncs using an ajax call and websocket messages. After the page load, the initial check is via ajax.  Once the websocket connection is open (if ever), further syncs are done over that protocol.  Using just an ajax service is satisfactory; however, you can get acheive more precise measurements by using a websocket.

**Web Service**  
Simply a webservice that returns the server's unix (ms) time.  For go, see gotime.NowHandler or gotime.Now() in golang.


**Websocket**  
As shown in the setup portion, implementing the messaging is up to you, but you must provide GoTime with a callback that will send the time request and notify GoTime when the response arrives.


Usage After Setup  
-----------------  
At any time, you can call GoTime() to get a Date object.  Note that GoTime might not have had a chance to sync yet.

```javascript
var time = new GoTime();
// Mon May 19 2014 15:38:07 GMT-0700 (PDT)
or 
var time = GoTime.now()
// 1400539092790
```

**Internal Information**
```javascript
GoTime.getOffset()
```
returns the difference between your clock and servertime.  Positive or negative

```javascript
GoTime.getPrecision()
```
returns the number of milliseconds GoTime may differ from servertime.

```javascript
GoTime.getLastMethod()
```
returns "ajax" or "websocket" for the last sync method

```javascript
GoTime.getSyncCount()
```
returns amount of times GoTime has synced

```javascript
GoTime.getHistory()
```
returns list of objects { Sample: { offset: 0, precision: 0 }, Method: "websocket or ajax", Time: (Date) } of all syncs since page load
