import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let ownCache=OwnCacheChannel()
  private let push = PathsPushNotifications()
  private let tracker = PathsLocationTracker()
  private var channel: FlutterMethodChannel?
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in self?.tracker.visibility(true) }
    NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in self?.tracker.visibility(false) }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) { push.registered(deviceToken); super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken) }
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) { push.failRegistration(); super.application(application, didFailToRegisterForRemoteNotificationsWithError: error) }
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PathsLocation") else { return }
    push.attach(registrar.messenger())
    ownCache.attach(registrar.messenger())
    let channel = FlutterMethodChannel(name: "paths/location", binaryMessenger: registrar.messenger())
    self.channel = channel
    tracker.emit = { [weak channel] event in channel?.invokeMethod("event", arguments:event) }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterError(code: "unavailable", message: "Tracker unavailable", details: nil)); return }
      do {
        switch call.method {
        case "runQueueProbe":
          #if DEBUG
          result(try self.tracker.runQueueProbe())
          #else
          result(FlutterMethodNotImplemented)
          #endif
        case "start": guard let policy = call.arguments as? [String: Any] else { throw PathsLocationTracker.TrackerError.policy }; try self.tracker.start(policy); result(nil)
        case "pause", "stopAndPurge": self.tracker.stop(); result(nil)
        case "pendingSamples": result(try self.tracker.pending())
        case "status": result(self.tracker.status())
        case "permissions": result(self.tracker.permissions())
        case "flushPending": self.tracker.flush(); result(nil)
        case "queueCount": result(try self.tracker.pending().count)
        case "acknowledge": try self.tracker.acknowledge(call.arguments as? [String] ?? []); result(nil)
        case "requestForegroundPermission": self.tracker.requestForeground { granted in result(granted) }
        case "requestBackgroundPermission": self.tracker.requestBackground { granted in result(granted) }
        case "openSettings": if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }; result(nil)
        default: result(FlutterMethodNotImplemented)
        }
      } catch { self.tracker.stop(); result(FlutterError(code: "tracker_unavailable", message: "Tracking stopped. Check precise location and system settings.", details: nil)) }
    }
  }
}
