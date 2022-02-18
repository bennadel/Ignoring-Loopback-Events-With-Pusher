<cfscript>

	config = deserializeJson( fileRead( "../config.json" ) );

	// For the sake of simplicity, I'm just re-creating the Pusher ColdFusion component on
	// every request. In a production context, I would cache this in the Application scope
	// or a dependency-injection (DI) container.
	pusher = new lib.Pusher(
		appID = config.pusher.appID,
		appKey = config.pusher.appKey,
		appSecret = config.pusher.appSecret,
		apiCluster = config.pusher.apiCluster
	);

	// ------------------------------------------------------------------------------- //
	// ------------------------------------------------------------------------------- //

	// This event will be pushed to ALL CLIENTS that are subscribed to the demo-channel,
	// including the browser that made THIS API call in the first place. In order to help
	// prevent the origin browser from responding to this event, let's echo the browser
	// UUID in the event payload.
	// --
	// NOTE: The Pusher API provides a mechanism for ignoring a given SocketID when
	// publishing events. However, the part of our client-side code that makes the AJAX
	// calls doesn't know anything about Pusher (or the state of the connection). As such,
	// there's no SocketID to be injected into the AJAX call.
	pusher.trigger(
		channels = "demo-channel",
		eventType = "click",
		message = {
			browserUuid: ( request.browserUuid ?: "" )
		}
	);

</cfscript>
