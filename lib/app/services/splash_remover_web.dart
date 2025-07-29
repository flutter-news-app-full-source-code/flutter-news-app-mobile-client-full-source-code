import 'dart:js_interop';

/// Web-specific implementation that calls the JavaScript function
/// to remove the splash screen.
@JS('removeSplashFromWeb')
external void removeSplashFromWeb();
