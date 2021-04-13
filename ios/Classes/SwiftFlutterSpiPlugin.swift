import Flutter
import UIKit
import SPIClient_iOS

enum SpiError: Error {
    case unknown
}

public class SwiftFlutterSpiPlugin: NSObject, FlutterPlugin, SPIDelegate {

  var client = SPIClient()
  var spiChannel = FlutterMethodChannel()
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_spi", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterSpiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.spiChannel = channel
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
    
    public func spi(_ spi: SPIClient, statusChanged state: SPIState) {
        invokeFlutterMethod(flutterMethod:"statusChanged", message: state)
    }
    public func spi(_ spi: SPIClient, pairingFlowStateChanged state: SPIState) {
        invokeFlutterMethod(flutterMethod:"pairingFlowStateChanged", message: state)
    }
    public func spi(_ spi: SPIClient, transactionFlowStateChanged state: SPIState) {
        invokeFlutterMethod(flutterMethod:"txFlowStateChanged", message: state)
    }
    public func spi(_ spi: SPIClient!, secretsChanged secrets: SPISecrets?, state: SPIState!) {
        invokeFlutterMethod(flutterMethod:"secretsChanged", message: secrets)
    }
    public func spi(_ spi: SPIClient, deviceAddressChanged state: SPIState) {
        invokeFlutterMethod(flutterMethod:"deviceAddressChanged", message: state)
    }
    
    private func invokeFlutterMethod(flutterMethod: String, message: Any?) {
        spiChannel.invokeMethod(flutterMethod, arguments: message)
    }
    
    private func initSpi(posId: String,  eftposAddress: String, secrets: [String: String]?, result: @escaping FlutterResult) {
        client.posId = posId
        client.eftposAddress = eftposAddress
        client.posVendorId = "LinkPOS"
        client.posVersion = "1.0.0"
        if secrets != nil {
            client.setSecretEncKey(secrets?["encKey"], hmacKey: secrets?["hmacKey"])
        }
        // subscribe spi events
        result(nil)
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
