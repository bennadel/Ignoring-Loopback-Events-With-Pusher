component
	output = false
	hint = "I provide methods for interacting with the Pusher App API."
	{

	/**
	* I initialize the Pusher client with the given application settings.
	*/
	public void function init(
		required string appID,
		required string appKey,
		required string appSecret,
		required string apiCluster,
		numeric defaultTimeout = 10
		) {

		variables.appID = arguments.appID;
		variables.appKey = arguments.appKey;
		variables.appSecret = arguments.appSecret;
		variables.apiCluster = arguments.apiCluster;
		variables.defaultTimeout = arguments.defaultTimeout;

		// When sending an event to multiple channels at one time, the Pusher API only
		// allows for upto 100 channels to be targeted within a single request. If an
		// event needs to go to more channels, the groupings will be spread across
		// multiple HTTP requests.
		variables.maxChannelChunkSize = 100;
		variables.newline = chr( 10 );

	}

	// ---
	// PUBLIC METHODS.
	// ---

	/**
	* I trigger the given event on the given channel (singular) or set of channels.
	* 
	* CAUTION: Since the API request may need to be split across multiple HTTP requests,
	* based on the number of channels being targeted, the overall API request workflow
	* should NOT be considered as atomic. One "chunk" of channels may work and then a
	* subsequent "chunk" may fail. As such, it is recommended that each API request be
	* kept under the max-channel limit.
	*/
	public void function trigger(
		required any channels,
		required string eventType,
		required any message,
		numeric timeout = defaultTimeout
		) {

		// When sending an event to multiple channels, there is a cap on how many channels
		// can be designated in each request. As such, we have to chunk the channels up
		// into consumable groups.
		var channelChunks = isSimpleValue( channels )
			? buildChannelChunks( [ channels ] )
			: buildChannelChunks( channels )
		;

		var serializedMessage = serializeJson( message );

		for ( var channelChunk in channelChunks ) {

			makeApiRequest(
				method = "POST",
				path = "/apps/#appID#/events",
				body = serializeJson({
					name: eventType,
					data: serializedMessage,
					channels: channelChunk
				}),
				timeout = timeout
			);

		}

	}

	// ---
	// PRIVATE METHODS.
	// ---

	/**
	* I split the given collection of channels up into chunks that can fit into a single
	* API request.
	*/
	private array function buildChannelChunks( required array channels ) {

		var chunks = [];
		var chunk = [];

		for ( var channel in channels ) {

			chunk.append( channel );

			// If the current chunk has reached capacity, move onto the next chunk.
			if ( chunk.len() == maxChannelChunkSize ) {

				chunks.append( chunk );
				chunk = [];

			}

		}

		// Since chunks are appended only when a new chunk is being created, let's gather
		// the last chunk if it has any channels in it.
		if ( chunk.len() ) {

			chunks.append( chunk );

		}

		return( chunks );

	}


	/**
	* I generate the API request signature for the given request values.
	*/
	private string function generateSignature(
		required string method,
		required string path,
		required string authKey,
		required string authTimestamp,
		required string authVersion,
		required string bodyMd5,
		) {

		var parts = [
			method, newline,
			path, newline,
			"auth_key=#authKey#&",
			"auth_timestamp=#authTimestamp#&",
			"auth_version=#authVersion#&",
			"body_md5=#bodyMd5#"
		];
		// CAUTION: Signature MUST BE LOWER-CASE or it will be rejected by Pusher.
		var signature = hmac( parts.toList( "" ), appSecret, "HmacSHA256", "utf-8" )
			.lcase()
		;

		return( signature );

	}


	/**
	* I make the HTTP request to the Pusher API. The parsed payload is returned; or, an
	* error is thrown if the HTTP request was not successful.
	*/
	private struct function makeApiRequest(
		required string method,
		required string path,
		required string body,
		required numeric timeout
		) {

		var domain = ( apiCluster.len() )
			? "https://api-#apiCluster#.pusher.com"
			: "https://api.pusher.com"
		;
		var endpoint = "#domain##path#";
		var bodyMd5 = hash( body, "md5" ).lcase();
		var authKey = appKey;
		// The authentication timestamp must be in Epoch SECONDS. Pusher will reject any
		// request that is outside of 600-seconds from the current time.
		var authTimestamp = fix( getTickCount() / 1000 );
		var authVersion = "1.0";
		var authSignature = generateSignature(
			method = method,
			path = path,
			authKey = authKey,
			authTimestamp = authTimestamp,
			authVersion = authVersion,
			bodyMd5 = bodyMd5
		);

		http
			result = "local.httpResponse"
			method = method
			url = endpoint
			charset = "utf-8"
			timeout = timeout
			getAsBinary = "yes"
			{

			httpParam
				type = "header"
				name = "Content-Type"
				value = "application/json"
			;
			httpParam
				type = "url"
				name = "auth_key"
				value = authKey
			;
			httpParam
				type = "url"
				name = "auth_signature"
				value = authSignature
			;
			httpParam
				type = "url"
				name = "auth_timestamp"
				value = authTimestamp
			;
			httpParam
				type = "url"
				name = "auth_version"
				value = authVersion
			;
			httpParam
				type = "url"
				name = "body_md5"
				value = bodyMd5
			;
			httpParam
				type = "body"
				value = body
			;
		}

		// Even though we are asking the request to always return a Binary value, the type
		// is only guaranteed if the request comes back successfully. If something goes
		// wrong (such as a "Connection Failure"), the fileContent will still be returned
		// as a simple string. As such, we have to normalize the extracted payload.
		var fileContent = isBinary( httpResponse.fileContent )
			? charsetEncode( httpResponse.fileContent, "utf-8" )
			: httpResponse.fileContent
		;

		if ( ! httpResponse.statusCode.reFind( "2\d\d" ) ) {

			throw(
				type = "Pusher.NonSuccessStatusCode",
				message = "Pusher API returned with non-2xx status code.",
				extendedInfo = serializeJson({
					method: method,
					endpoint: endpoint,
					statusCode: httpResponse.statusCode,
					fileContent: fileContent
				})
			);

		}

		try {

			return( deserializeJson( fileContent ) );

		} catch ( any error ) {

			throw(
				type = "Pusher.JsonParseError",
				message = "Pusher API response could not be parsed as JSON.",
				extendedInfo = serializeJson({
					method: method,
					endpoint: endpoint,
					statusCode: httpResponse.statusCode,
					fileContent: fileContent
				})
			);

		}

	}

}
