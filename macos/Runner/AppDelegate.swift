import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationWillFinishLaunching(_ notification: Notification) {
    applyApplicationIcon()
    super.applicationWillFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// Asset Catalog icon is not always picked up by Dock on first launch after
  /// icon changes; set it explicitly from AppIcon.icns / AppIcon.appiconset.
  private func applyApplicationIcon() {
    if let icon = NSImage(named: NSImage.Name("AppIcon")) {
      NSApp.applicationIconImage = icon
      return
    }

    if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
       let icon = NSImage(contentsOf: url) {
      NSApp.applicationIconImage = icon
    }
  }
}
