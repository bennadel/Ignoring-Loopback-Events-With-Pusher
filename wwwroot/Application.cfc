component
	output = false
	hint = "I define the ColdFusion application settings and event-handlers."
	{

	// Define application settings.
	this.name = "PusherClientIdRoundTrip";
	this.applicationTimeout = createTimeSpan( 0, 1, 0, 0 );
	this.sessionManagement = false;

	this.directory = getDirectoryFromPath( getCurrentTemplatePath() );
	this.root = "#this.directory#../";

	// Define per-application mappings.
	this.mappings = {
		"/lib": "#this.root#lib"
	};

	// ---
	// PUBLIC METHODS.
	// ---

	/**
	* I get called once at the start of each incoming ColdFusion request.
	*/
	public void function onRequestStart() {

		var httpHeaders = getHttpRequestData( false ).headers;

		// When the browser is making AJAX calls to the API, it's going to inject a UUID
		// for each client into the incoming HTTP Headers. Let's pluck that out and store
		// it in the REQUEST scope where it can be globally-available from within the
		// processing of the current request.
		request.browserUuid = ( httpHeaders[ "X-Browser-UUID" ] ?: "" );

	}

}
