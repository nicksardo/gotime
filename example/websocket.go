package main

import (
    "net/http"
    "github.com/gorilla/websocket"
	"github.com/NickSardo/GoTime"
)

var upgrader *websocket.Upgrader

func init() {
    upgrader = &websocket.Upgrader{ReadBufferSize: 1024, WriteBufferSize: 1024}
}

type connection struct {
    // The websocket connection.
    ws *websocket.Conn

    // Buffered channel of outbound messages.
    send chan []byte
}

func (c *connection) reader() {
    for {
        _, message, err := c.ws.ReadMessage()
        if err != nil {
            break
        }

        switch string(message){
        case "time":
            c.ws.WriteMessage(websocket.TextMessage, []byte(gotime.Now()))
        default:
            // do nothing
        }

    }
    c.ws.Close()
}

func (c *connection) writer() {
    for message := range c.send {
        err := c.ws.WriteMessage(websocket.TextMessage, message)
        if err != nil {
            break
        }
    }
    c.ws.Close()
}

func wsHandler(w http.ResponseWriter, r *http.Request) {
    ws, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        return
    }
    c := &connection{send: make(chan []byte, 256), ws: ws}
    //h.register <- c
    //defer func() { h.unregister <- c }()
    //go c.writer()
    go c.reader()
}
