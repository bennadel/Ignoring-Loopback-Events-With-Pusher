
# Ignoring Loopback WebSocket Events From Pusher In Lucee CFML 5.3.8.206

by [Ben Nadel][bennadel]

Historically, one issue that I've wrestled with when using Pusher for WebSocket events in my ColdFusion application is the fact that events that one browser triggers are often published _back to that same browser_. This often leads to subsequent _and unnecessary_ data-loading in the client-side Single-Page Application (SPA). As such, I want to explore the use of a round-trip browser UUID that is injected into each API call as a means to help the origin browser ignore loopback events. This way, I can _optimistically_ respond to events locally and then _ignore_ those same events when they come back over the Pusher WebSocket.

[Read my **blog post** relating to this project][blog-4209]. &rarr;


[bennadel]: https://www.bennadel.com/

[blog-4209]: https://www.bennadel.com/blog/4209-ignoring-loopback-websocket-events-from-pusher-in-lucee-cfml-5-3-8-206.htm
