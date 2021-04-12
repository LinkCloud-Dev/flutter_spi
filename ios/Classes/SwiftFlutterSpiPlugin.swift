import Flutter
import UIKit
import SPIClient_iOS

enum SpiError: Error {
    case unknown
}

public class SwiftFlutterSpiPlugin: NSObject, FlutterPlugin {

  var client = SPIClient()
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_spi", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterSpiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
        if (call.method == "getPlatformVersion") {
            result("iOS " + UIDevice.current.systemVersion)
        } else if (call.method == "start") {
            start(result: result)
        } else if (call.method == "getVersion") {
            getVersion(result: result)
        } else if (call.method == "setPosId") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            setPosId(id: args["posId"] as! String, result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    } catch {
        result(FlutterError(code: "ERROR",
                                message: "Error",
                                details: nil))
    }
  }
    
    private func start(result: @escaping FlutterResult) {
        client.start()
        result(nil)
    }
    
    private func getVersion(result: @escaping FlutterResult) {
        result(SPIClient.getVersion())
    }
    
    private func setPosId(id: String, result: @escaping FlutterResult) {
        client.posId = id
        result(nil)
    }
}
