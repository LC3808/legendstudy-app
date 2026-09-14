import Flutter
import UIKit
import Darwin
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let processClockIdentity = "process:" + UUID().uuidString
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let notification = FlutterMethodChannel(name: "com.legendstudy.app/mock-notification", binaryMessenger: controller.binaryMessenger)
      notification.setMethodCallHandler { call, result in
        let center = UNUserNotificationCenter.current()
        let identifier = "legendstudy.mock.end"
        switch call.method {
        case "request":
          center.requestAuthorization(options: [.alert, .sound]) { allowed, _ in
            DispatchQueue.main.async { result(allowed) }
          }
        case "replace":
          center.removePendingNotificationRequests(withIdentifiers: [identifier])
          center.removeDeliveredNotifications(withIdentifiers: [identifier])
          guard let args = call.arguments as? [String: Any], let session = args["session"] as? String,
                let ms = args["remainingMs"] as? NSNumber, ms.doubleValue > 0 else { result(nil); return }
          let content = UNMutableNotificationContent()
          content.title = "레전드스터디"
          content.body = "모의고사 시간이 종료됐어요."
          content.sound = .default
          content.userInfo = ["studySession": session]
          let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, min(43200, ms.doubleValue / 1000)), repeats: false)
          center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)) { error in
            DispatchQueue.main.async {
              if error != nil { result(FlutterError(code: "MOCK_ALERT", message: "Reminder unavailable", details: nil)) }
              else { result(nil) }
            }
          }
        default: result(FlutterMethodNotImplemented)
        }
      }
      // iOS supports manual Focus guidance, not automatic system Focus activation.
      let focus = FlutterMethodChannel(name: "com.legendstudy.app/focus", binaryMessenger: controller.binaryMessenger)
      focus.setMethodCallHandler { call, result in
        do {
          switch call.method {
          case "status": result(["capability": "guideOnly", "permission": false])
          case "readPreference", "writePreference":
            let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            var folder = support.appendingPathComponent("StudyFocusLocal", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var flags = URLResourceValues()
            flags.isExcludedFromBackup = true
            try folder.setResourceValues(flags)
            let file = folder.appendingPathComponent("preference.txt")
            if call.method == "readPreference" {
              result(FileManager.default.fileExists(atPath: file.path) ? try String(contentsOf: file, encoding: .utf8) : "ask")
            } else {
              guard let value = call.arguments as? String, ["ask", "always", "disabled"].contains(value), let data = value.data(using: .utf8) else {
                result(FlutterError(code: "FOCUS_INPUT", message: "Invalid focus preference", details: nil)); return
              }
              try data.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
              result(nil)
            }
          case "activate": result("unsupported")
          case "requestPermission", "reconcile": result(nil)
          default: result(FlutterMethodNotImplemented)
          }
        } catch { result(FlutterError(code: "FOCUS_UNAVAILABLE", message: "Focus unavailable", details: nil)) }
      }
      let channel = FlutterMethodChannel(name: "com.legendstudy.app/study", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        do {
          let folder = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
          let file = folder.appendingPathComponent("study-state-v1.json")
          switch call.method {
          case "clock":
            var info = mach_timebase_info_data_t()
            mach_timebase_info(&info)
            let elapsed = Double(mach_continuous_time()) * Double(info.numer) / Double(info.denom) / 1_000_000
            var boot = timeval()
            var size = MemoryLayout<timeval>.size
            let valid = sysctlbyname("kern.boottime", &boot, &size, nil, 0) == 0
            result(["utcMs": Int64(Date().timeIntervalSince1970 * 1000), "elapsedMs": Int64(elapsed),
                    "boot": valid ? "\(boot.tv_sec):\(boot.tv_usec)" : self.processClockIdentity])
          case "read":
            result(FileManager.default.fileExists(atPath: file.path) ? try String(contentsOf: file, encoding: .utf8) : nil)
          case "write":
            guard let text = call.arguments as? String, let data = text.data(using: .utf8) else {
              result(FlutterError(code: "STUDY_LOCAL_INPUT", message: "Invalid local study data", details: nil)); return
            }
            try data.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            result(nil)
          default: result(FlutterMethodNotImplemented)
          }
        } catch { result(FlutterError(code: "STUDY_LOCAL_IO", message: "Local study operation failed", details: nil)) }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
