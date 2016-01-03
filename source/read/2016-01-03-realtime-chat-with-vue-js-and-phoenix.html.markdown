---
title: Realtime chat with Vue.js and Phoenix
date: 2016-01-03 14:33 UTC
tags: Elixir, Phoenix, Vue.js, Javascript
change_frequency: never
ogp:
  og:
    description: "Realtime chat with Vue.js and Phoenix"
    title: "Realtime chat with Vue.js and Phoenix"
    url: 'read/realtime-chat-with-vue-js-and-phoenix'
---

Vue.js is a javascript framework for "Reactive Components for Modern Web Interfaces".  Vue.js allows for you to make small components on your page as well as full-blown single page applications. 

Sometimes all I want is a component or two on a page rather than investing the website's whole infrastructure in a Javascript framework and this is why I enjoy using Vue.js.

This quick tutorial uses the backend of the Phoenix [channel tutorial located on the official website](http://www.phoenixframework.org/docs/channels#section-tying-it-all-together) and gives an alternative for the front end code built with Vue.js to illustrate how easy it is to use these two technologies together.

I won't be explaining the backend code as I would be parroting what's on the Phoenix documentation. Please read the above link for a full understanding. You can copy the code snippets below before we move on to integrating Vue.js

## Versions

Elixir 1.1
Phoenix 1.1
Vue.js 1.0.13

## Channel Code

Run ```mix phoenix.new chat``` to set up the new application.

```elixir
// web/channels/user_socket.ex
defmodule Chat.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "rooms:lobby", Chat.RoomChannel

  transport :websocket, Phoenix.Transports.WebSocket
 
  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
```

```elixir
//web/channels/room_channel.ex
defmodule Chat.RoomChannel do
  use Chat.Web, :channel

  def join("rooms:lobby", payload, socket) do
    {:ok, socket}
  end

  def join("rooms:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "Unauthorized"}}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body}
    {:noreply, socket}
  end

  def handle_out("new_msg", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end
end
```

The router and page controller, view and template should all be generated automatically when the app was made.

## Integrating Vue.js

First up, let's get Vue.js set up with Phoenix. There are few ways to do this. Here are a couple of options to get you started.

1. Copy a CDN link into ```web/templates/layout/app.html.ex```.

The javascript can be included like so

```
<script src="http://cdnjs.cloudflare.com/ajax/libs/vue/1.0.13/vue.min.js"></script>
<script src="<%= static_path(@conn, "/js/app.js") %>"></script>
```

2.  Place Vue.js in your web/static/vendor/ directory

Brunch is set up to include any code in the vendor directory on compilation so it will be available with the other scripts.

You can download Vue.js from the website manually, or use NPM and copy it.

```bash
npm install vue --save-dev
```

```bash
cp node_modules/vue/dist/vue.js web/static/vendor/vue.js
```

Now running ```brunch build``` or ```mix phoenix.server``` will compile Vue.js with your Javascript.

## Setting up the HTML

Edit your ```web/templates/page/index.html.ex``` like so

```elixir
<div id="app">
  <ul>
    <li v-for="message in messages">
      [{{ message.at }}] {{ message.body }}
    </li>
  </ul>
  <input type-"text" v-model="newMessage" v-on:keyup.13="sendNewMessage">
</div>
```

The div with the ID "app" will be used by Vue.js, any code inside here is going to be available.

There's a ```v-for="message in messages"``` on line 3 which will loop through an array of objects.

Line 4 will output the chat messages and the time they were added.

Line 7 is an input box, bound to Vue.js by ```v-model="newMessage"``` and will trigger a ```sendNewMessage``` method when the Enter key (13) is pressed.

Booting up the Phoenix server with ```mix phoenix.server``` will show a bunch of curly brackets as we haven't initialized the Vue.js Javascript yet.

![Pre Vue.js preview](http://i.imgur.com/wCfowYv.png)

## Javascript

Now in ```web/static/js/app.js``` uncomment the socket import.

In web/static/js/socket.js add this code

```javascript
import {Socket} from "deps/phoenix/web/static/js/phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

socket.connect()

let app = new Vue({
  el: '#app',
  ready() {
    this.channel = socket.channel("rooms:lobby", {});
    this.channel.on("new_msg", payload => {
      payload.at = Date();
      this.messages.push(payload);
    });
    this.channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })
  },
  data: {
    messages: [],
    newMessage: '',
    channel: null,
  },
  computed: {
  
  },
  methods: {
    sendNewMessage() {
      this.channel.push("new_msg", {body: this.newMessage});
      this.newMessage = '';
    }
  }
});

export default socket
```

The import socket, socket.connect() is unchanged. The Vue.js class uses el to know which HTML to use. The ```ready``` method is a lifecycle hook which is called after Vue has finished compilation (There's a nice diagram here of all the lifecycle hooks http://vuejs.org/guide/instance.html#Lifecycle_Diagram).

We have set the channel to an instance variable in the ```ready``` method.  So we can call it in various places throughout the code. This will be useful shortly when we need to push an event to the server.

The ready method is also where we join the ```rooms:lobby``` and subscribe to the ```new_msg``` event from Phoenix. When this event is sent from the server we append the new message to our ```messages``` instance variable which then automatically shows in the HTML we wrote previously (the ```v-for``` loop).

There's a ```methods``` object where we put the ```sendNewMessage``` method which is triggered from the ```newMessage``` input we wrote earlier. This method pushes the message to Phoenix, ready to be published across all connections. It then sets ```newMessage``` to '' so the user can begin typing a fresh message.

At this point if you reload the page the curly brackets should disappear. When you enter a new message it should appear in the list!

![Vue.js preview](http://i.imgur.com/w2pa5zo.png)

That's all there is to it! Try opening multiple windows and messaging between each to see it in action.

## Bonus points

Add Moment.js for a simpler date format

```javascript
payload.at = moment().format('YYYY-MM-DD HH:mm:ss');
```

Style with CSS!

```javascript
<!-- web/templates/page/index.html.ex -->
<span class="brackets">[</span><span class="time">{{ message.at }}</span><span class="brackets">]</span> {{ message.body }}
```

```css
#app ul {
  list-style-type: none;
  padding: 0;
}

#app li {
  padding: 5px 0;
}

.brackets {
  color: #ccc;
}

.time {
  color: #999;
  font-style:italic;
}

input {
  width: 100%;
}
```

![Vue.js styled preview](http://i.imgur.com/W0GLq6X.png)

There's a lot more you can do with both Phoenix and Vue.js and I may look at writing some more articles in the future. For now we have a Vue.js frontend which works with the Phoenix channel tutorial backend.
