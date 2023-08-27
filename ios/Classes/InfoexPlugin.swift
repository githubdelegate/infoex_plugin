import Flutter
import UIKit

public class InfoexPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "infoex", binaryMessenger: registrar.messenger())
    let instance = InfoexPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "ie":
//        Task {
//            DispatchQueue.main.asyncAfter(deadline:.now() + 2) {
//                DispatchQueue.main.async {
//                    result([
//                        "formats": "xxx"
//                    ])
//                }
//            }
//        }
        
//        result([
//            "formats": "xxx"
//        ])
        let weburl = call.arguments as? String  ?? ""
        Task {
            let format = await XVideoIE()._real_extract(url: weburl)
            DispatchQueue.main.async {
                result(format)
            }
        }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
