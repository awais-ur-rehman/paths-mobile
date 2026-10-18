import Flutter
import UIKit
import UserNotifications

final class PathsPushNotifications: NSObject, UNUserNotificationCenterDelegate {
  private let store = UserDefaults.standard
  private var channel: FlutterMethodChannel?
  private var token: String?
  private var waiting: FlutterResult?
  private var timeout: DispatchWorkItem?
  private var configured = false
  private var asking = false
  private var generation: Int { store.integer(forKey: "paths.push.generation") }
  func attach(_ messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "paths/push", binaryMessenger: messenger)
    UNUserNotificationCenter.current().delegate = self
    channel?.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterError(code: "unavailable", message: "Push unavailable", details: nil)); return }
      switch call.method {
      case "configure": self.configured = (call.arguments as? [String: Any])?["apnsEnabled"] as? Bool == true; result(nil)
      case "status":
        UNUserNotificationCenter.current().getNotificationSettings { settings in DispatchQueue.main.async {
          result(["configured": self.configured, "granted": settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional, "optedIn": self.store.bool(forKey: "paths.push.enabled"), "bound": self.store.string(forKey: "paths.push.binding") != nil])
        }}
      case "requestPermission":
        guard self.configured, !self.asking else { result(FlutterError(code: "unavailable", message: "Push unavailable", details: nil)); return }
        self.asking = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { allowed, error in DispatchQueue.main.async {
          self.asking = false
          if error != nil { result(FlutterError(code: "permission", message: "Permission unavailable", details: nil)) } else { result(allowed) }
        }}
      case "token":
        guard self.configured, self.waiting == nil else { result(FlutterError(code: "unavailable", message: "Push unavailable", details: nil)); return }
        if let token = self.token { result(["provider": "apns", "token": token]); return }
        self.waiting = result
        let timer = DispatchWorkItem { [weak self] in self?.failRegistration() }
        self.timeout = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timer)
        UIApplication.shared.registerForRemoteNotifications()
      case "nextGeneration":
        guard self.generation < Int32.max else { result(FlutterError(code: "storage", message: "Registration generation exhausted", details: nil)); return }
        let next = self.generation + 1; self.store.set(next, forKey: "paths.push.generation"); result(next)
      case "bind":
        guard let args = call.arguments as? [String: Any], let binding = args["bindingId"] as? String, UUID(uuidString: binding) != nil, let generation = args["generation"] as? Int, generation == self.generation else { result(false); return }
        self.store.set(binding, forKey: "paths.push.binding"); self.store.set(true, forKey: "paths.push.enabled"); result(true)
      case "clear":
        if self.generation < Int32.max { self.store.set(self.generation + 1, forKey: "paths.push.generation") }
        self.store.set(false, forKey: "paths.push.enabled")
        ["paths.push.binding", "paths.push.tap", "paths.push.seen"].forEach { self.store.removeObject(forKey: $0) }
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UIApplication.shared.unregisterForRemoteNotifications()
        self.token = nil; self.failRegistration(); result(nil)
      case "pendingTap": let value = self.store.string(forKey: "paths.push.tap"); self.store.removeObject(forKey: "paths.push.tap"); result(value)
      case "openSettings": if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }; result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }
  func registered(_ data: Data) {
    token = data.map { String(format: "%02x", $0) }.joined()
    timeout?.cancel(); timeout = nil
    if let result = waiting { waiting = nil; result(["provider": "apns", "token": token!]) }
    else { channel?.invokeMethod("tokenChanged", arguments: nil) }
  }
  func failRegistration() { timeout?.cancel(); timeout = nil; let result = waiting; waiting = nil; result?(FlutterError(code: "unavailable", message: "Push registration unavailable", details: nil)) }
  private func event(_ data: [AnyHashable: Any]) -> String? {
    guard store.bool(forKey: "paths.push.enabled"), let event = data["eventId"] as? String, UUID(uuidString: event) != nil, let binding = data["bindingId"] as? String, binding == store.string(forKey: "paths.push.binding"), let kind = data["kind"] as? String, ["encounter", "request_received", "request_accepted", "message"].contains(kind) else { return nil }
    return event
  }
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    guard let event = event(notification.request.content.userInfo) else { completionHandler([]); return }
    var seen = store.stringArray(forKey: "paths.push.seen") ?? []
    guard !seen.contains(event) else { completionHandler([]); return }
    seen.append(event); store.set(Array(seen.suffix(100)), forKey: "paths.push.seen")
    channel?.invokeMethod("received", arguments: nil)
    completionHandler([.banner, .sound])
  }
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    if let id = event(response.notification.request.content.userInfo) { store.set(id, forKey: "paths.push.tap"); channel?.invokeMethod("tap", arguments: id) }
    completionHandler()
  }
  deinit { timeout?.cancel(); channel?.setMethodCallHandler(nil) }
}
