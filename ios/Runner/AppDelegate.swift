import Flutter
import UIKit
import Darwin

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let processClockIdentity = "process:" + UUID().uuidString
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
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
