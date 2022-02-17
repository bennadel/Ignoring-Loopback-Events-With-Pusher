<cfscript>

	config = deserializeJson( fileRead( "../config.json" ) );

	// In order to setup the Pusher client in the browser, we need to pass-down some of
	// configuration data. DO NOT SEND DOWN APP SECRET!
	clientConfig = serializeJson({
		appKey: config.pusher.appKey,
		apiCluster: config.pusher.apiCluster,
	});

</cfscript>

<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>
		Ignoring Loopback WebSocket Events From Pusher In Lucee CFML 5.3.8.206
	</title>
</head>
<body style="user-select: none ;">

	<h1>
		Ignoring Loopback WebSocket Events From Pusher In Lucee CFML 5.3.8.206
	</h1>

	<!---
		This counter value will be incremented both locally via click-handlers and
		remotely via Pusher WebSockets. The goal is not to keep the counter in sync across
		clients, only to emit events across clients (keeping it super simple).
	--->
	<div class="counter" style="font-size: 40px ;">
		0
	</div>


	<script type="text/javascript" src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
	<script type="text/javascript" src="https://js.pusher.com/7.0/pusher.min.js"></script>
	<script type="text/javascript">

		var config = JSON.parse( "<cfoutput>#encodeForJavaScript( clientConfig )#</cfoutput>" );
		// Let's assign a universally-unique ID to every browser that the app renders.
		// This UUID will be "injected" into each outgoing API AJAX request as an HTTP
		// header. This is not specifically tied to the Pusher functionality; but, will be
		// used to prevent "loop back" events.
		var browserUuid = "browser-<cfoutput>#createUuid()#</cfoutput>";

		// --------------------------------------------------------------------------- //
		// --------------------------------------------------------------------------- //

		var pusher = new Pusher(
			config.appKey,
			{
				cluster: config.apiCluster
			}
		);

		var channel = pusher.subscribe( "demo-channel" );

		// Listen for all "click" WebSocket events on our demo channel.
		channel.bind(
			"click",
			function handleEvent( data ) {

				console.group( "Pusher Event" );
				console.log( data );
				console.groupEnd();

				// When the ColdFusion server sends a "click" event to the Pusher API,
				// Pusher turns around and sends that event to every client that is
				// subscribed on the channel, including THIS BROWSER. However, since we're
				// OPTIMISTICALLY INCREMENTING THE COUNTER LOCALLY, we don't want to ALSO
				// increment it based on the WebSocket event. As such, we want to ignore
				// any events that were triggered by THIS browser.
				if ( data.browserUuid === browserUuid ) {

					console.warn( "Ignoring loopback event from local click." );
					return;

				}

				// If this event came from a DIFFERENT browser, then let's update our
				// count locally to reflect the event.
				incrementCounter();

			}
		);

		// --------------------------------------------------------------------------- //
		// --------------------------------------------------------------------------- //

		// Each count will be locally-stored in the browser. The point of this demo isn't
		// to synchronize the counts across browsers, it's to prevent loopback event
		// processing for a single browser.
		var count = 0;
		var counter = $( ".counter" );

		jQuery( document ).click( handleDocumentClick );


		/**
		* I handle clicks on the document, using them to trigger click API calls.
		*/
		function handleDocumentClick( event ) {

			// OPTIMISTICALLY increment the counter locally.
			incrementCounter();

			// Make an API call to trigger the click event on all Pusher-subscribed
			// clients. We're including the browser's UUID so that we can later ignore
			// loopback events for this client.
			$.ajax({
				method: "post",
				url: "./api.cfm",
				headers: {
					"X-Browser-UUID": browserUuid
				}
			});

		}


		/**
		* I increment the current count and render it to the DOM.
		*/
		function incrementCounter() {

			counter.html( ++count );

		}

	</script>
</body>
</html>
