import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// Detaches the window_manager plugin's NSWindowDelegate before the Flutter
  /// engine is torn down: AppKit posts window notifications (resize/order-out)
  /// while destroying the window during termination, and forwarding them to a
  /// destroyed engine logs "Failed to create a FlutterPlatformMessageResponseHandle".
  // Note: FlutterAppDelegate declares but does not implement this selector,
  // so there is no super implementation to call.
  override func applicationWillTerminate(_ notification: Notification) {
    mainFlutterWindow?.delegate = nil
  }
}
