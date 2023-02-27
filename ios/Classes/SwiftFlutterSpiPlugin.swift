import Flutter
import UIKit
import SPIClient_iOS

enum SpiError: Error {
    case unknown
}

extension SPIStatus {
    var name: String {
        switch self {
        case .unpaired:
            return "UNPAIRED"
        case .pairedConnecting:
            return "PAIRED_CONNECTING"
        case .pairedConnected:
            return "PAIRED_CONNECTED"
        default:
            return ""
        }
    }
}

extension SPIFlow {
    var name: String {
        switch self {
        case .idle:
            return "IDLE"
        case .pairing:
            return "PAIRING"
        case .transaction:
            return "TRANSACTION"
        default:
            return ""
        }
    }
}

extension SPITransactionType {
    var name: String {
        switch self {
        case .getLastTransaction:
            return "GET_LAST_TRANSACTION"
        case .purchase:
            return "PURCHASE"
        case .refund:
            return "REFUND"
        case .settle:
            return "SETTLE"
        case .cashoutOnly:
            return "CASHOUT_ONLY"
        case .MOTO:
            return "MOTO"
        case .settleEnquiry:
            return "SETTLEMENT_ENQUIRY"
        case .preAuth:
            return "PREAUTH"
        case .accountVerify:
            return "ACCOUNT_VERIFY"
        default:
            return ""
        }
    }
}

public class SwiftFlutterSpiPlugin: NSObject, FlutterPlugin, SPIDelegate {
    
    private static var _instance: SwiftFlutterSpiPlugin = SwiftFlutterSpiPlugin()

  var client = SPIClient()
  var spiChannel = FlutterMethodChannel()
    
    static var current: SwiftFlutterSpiPlugin {
        return _instance
    }
    
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
        } else if (call.method == "init") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            initSpi(
                posId: args["posId"] as! String,
                eftposAddress: args["eftposAddress"] as! String,
                serialNumber: args["serialNumber"] as! String,
                secrets: args["secrets"] as? [String: String],
                result: result
            )
        } else if (call.method == "start") {
            start(result: result)
        } else if (call.method == "setPosId") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            setPosId(id: args["posId"] as! String, result: result)
        } else if (call.method == "setSerialNumber") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            setSerialNumber(serialNumber: args["serialNumber"] as! String, result: result)
        } else if (call.method == "getVersion") {
            getVersion(result: result)
        } else if (call.method == "getDeviceSN") {
            getDeviceSN(result: result)
        } else if (call.method == "setEftposAddress") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            setEftposAddress(address: args["address"] as! String, result: result)
        } else if (call.method == "getCurrentStatus") {
            getCurrentStatus(result: result)
        } else if (call.method == "getCurrentFlow") {
            getCurrentFlow(result: result)
        } else if (call.method == "getCurrentPairingFlowState") {
            getCurrentPairingFlowState(result: result)
        } else if (call.method == "getCurrentTxFlowState") {
            getCurrentTxFlowState(result: result)
        } else if (call.method == "getConfig") {
            getConfig(result: result)
        } else if (call.method == "ackFlowEndedAndBackToIdle") {
            ackFlowEndedAndBackToIdle(result: result)
        } else if (call.method == "pair") {
            pair(result: result)
        } else if (call.method == "pairingConfirmCode") {
            pairingConfirmCode(result: result)
        } else if (call.method == "pairingCancel") {
            pairingCancel(result: result)
        } else if (call.method == "unpair") {
            unpair(result: result)
        } else if (call.method == "initiatePurchaseTx") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            initiatePurchaseTx(
                posRefId: args["posRefId"] as! String,
                purchaseAmount: args["purchaseAmount"] as! Int,
                tipAmount: args["tipAmount"] as! Int,
                cashoutAmount: args["cashoutAmount"] as! Int,
                promptForCashout: args["promptForCashout"] as! Bool,
                result: result
            )
        } else if (call.method == "initiateRefundTx") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            initiateRefundTx(
                posRefId: args["posRefId"] as! String,
                refundAmount: args["refundAmount"] as! Int,
                result: result
            )
        } else if (call.method == "acceptSignature") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            acceptSignature(
                accepted: args["accepted"] as! Bool,
                result: result
            )
        } else if (call.method == "submitAuthCode") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            submitAuthCode(
                authCode: args["accepted"] as! String,
                result: result
            )
        } else if (call.method == "cancelTransaction") {
            cancelTransaction(result: result)
        } else if (call.method == "initiateCashoutOnlyTx") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            initiateCashoutOnlyTx(
                posRefId: args["posRefId"] as! String,
                amountCents: args["amountCents"] as! Int,
                result: result
            )
        } else if (call.method == "initiateMotoPurchaseTx") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            initiateMotoPurchaseTx(
                posRefId: args["posRefId"] as! String,
                amountCents: args["amountCents"] as! Int,
                result: result
            )
        } else if (call.method == "initiateSettleTx") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            initiateSettleTx(
                id: args["id"] as! String,
                result: result
            )
        } else if (call.method == "initiateSettlementEnquiry") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            initiateSettlementEnquiry(
                posRefId: args["posRefId"] as! String,
                result: result
            )
        } else if (call.method == "initiateGetLastTx") {
            initiateGetLastTx(result: result)
        } else if (call.method == "dispose") {
            dispose(result: result)
        } else if (call.method == "setPromptForCustomerCopyOnEftpos") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            setPromptForCustomerCopyOnEftpos(
                promptForCustomerCopyOnEftpos: args["promptForCustomerCopyOnEftpos"] as! Bool,
                result: result
            )
        } else if (call.method == "setSignatureFlowOnEftpos") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            setSignatureFlowOnEftpos(
                signatureFlowOnEftpos: args["signatureFlowOnEftpos"] as! Bool,
                result: result
            )
        } else if (call.method == "setPrintMerchantCopy") {
            guard let args = call.arguments as? [String:Any] else {
                throw SpiError.unknown
            }
            setPrintMerchantCopy(
                printMerchantCopy: args["printMerchantCopy"] as! Bool,
                result: result
            )
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
        SPILogMsg("statusChanged \(state.status.name)")
        invokeFlutterMethod(flutterMethod:"statusChanged", message: state.status.name)
    }
    public func spi(_ spi: SPIClient, pairingFlowStateChanged state: SPIState) {
        invokeFlutterMethod(flutterMethod:"pairingFlowStateChanged", message: mapPairingFlowState(state: state.pairingFlowState))
    }
    public func spi(_ spi: SPIClient, transactionFlowStateChanged state: SPIState) {
        invokeFlutterMethod(flutterMethod:"txFlowStateChanged", message: mapTransactionState(state: state.txFlowState))
    }
    public func spi(_ spi: SPIClient!, secretsChanged secrets: SPISecrets?, state: SPIState!) {
        invokeFlutterMethod(flutterMethod:"secretsChanged", message: secrets != nil ? mapSecrets(obj: secrets!) : nil)
    }
    public func spi(_ spi: SPIClient, deviceAddressChanged state: SPIState) {
        invokeFlutterMethod(flutterMethod:"deviceAddressChanged", message: state.deviceAddressStatus.address)
    }
    
    private func invokeFlutterMethod(flutterMethod: String, message: Any?) {
        spiChannel.invokeMethod(flutterMethod, arguments: message)
    }
    
    private func initSpi(posId: String, eftposAddress: String, serialNumber: String, secrets: [String: String]?, result: @escaping FlutterResult) {
        client.posId = posId
        client.eftposAddress = eftposAddress
        client.serialNumber = serialNumber
        client.testMode = false
        client.autoAddressResolutionEnable = false
        client.posVendorId = "LinkPOS"
        client.posVersion = "1.0.0"
        
        if secrets != nil {
            client.setSecretEncKey(secrets?["encKey"], hmacKey: secrets?["hmacKey"])
        }
        // subscribe spi events
        client.delegate = self
        result(nil)
    }
    
    private func start(result: @escaping FlutterResult) {
        client.start()
        result(nil)
    }
    
    private func setPosId(id: String, result: @escaping FlutterResult) {
        client.posId = id
        result(nil)
    }

    private func setSerialNumber(serialNumber: String, result: @escaping Result) {
        client.serialNumber = serialNumber
        result(nil)
    }
    
    private func setEftposAddress(address: String, result: @escaping FlutterResult) {
        client.eftposAddress = address
        result(nil)
    }
    
    private func setPosInfo(posVendorId: String, posVersion: String, result: @escaping FlutterResult) {
        client.posVersion = posVersion
        client.posVendorId = posVendorId
        result(nil)
    }

    private func getVersion(result: @escaping FlutterResult) {
        result(SPIClient.getVersion())
    }
    
    private func getDeviceSN(result: @escaping FlutterResult) {
        result(UIDevice.current.identifierForVendor!.uuidString)
    }
    
    private func getCurrentStatus(result: @escaping FlutterResult) {
        result(client.state.status.name)
    }
    
    private func getCurrentFlow(result: @escaping FlutterResult) {
        result(client.state.flow.name)
    }
    
    private func getCurrentPairingFlowState(result: @escaping FlutterResult) {
        result(mapPairingFlowState(state: client.state.pairingFlowState))
    }
    
    private func getCurrentTxFlowState(result: @escaping FlutterResult) {
        result(mapPairingFlowState(state: client.state.pairingFlowState))
    }
    
    private func getConfig(result: @escaping FlutterResult) {
        result(mapSpiConfig(obj: client.config))
    }
    
    private func ackFlowEndedAndBackToIdle(result: @escaping FlutterResult) {
        client.ackFlowEndedAndBack { (_, state) in
            result(nil)
        }
    }
    
    private func pair(result: @escaping FlutterResult) {
        client.pair()
        result(nil)
    }
    
    private func pairingConfirmCode(result: @escaping FlutterResult) {
        client.pairingConfirmCode()
        result(nil)
    }
    
    private func pairingCancel(result: @escaping FlutterResult) {
        client.pairingCancel()
        result(nil)
    }
    
    private func unpair(result: @escaping FlutterResult) {
        client.unpair()
        result(nil)
    }
    
    private func initiatePurchaseTx(posRefId: String, purchaseAmount: Int, tipAmount: Int, cashoutAmount: Int, promptForCashout: Bool, result: @escaping FlutterResult) {
        // client.enablePayAtTable()
        client.initiatePurchaseTx(posRefId, purchaseAmount: purchaseAmount, tipAmount: tipAmount, cashoutAmount: cashoutAmount, promptForCashout: promptForCashout, completion: printResult)
        result(nil)
    }
    
    private func initiateRefundTx(posRefId: String, refundAmount: Int, result: @escaping FlutterResult) {
        client.initiateRefundTx(posRefId, amountCents: refundAmount, completion: printResult)
        result(nil)
    }
    
    private func acceptSignature(accepted: Bool, result: @escaping FlutterResult) {
        client.acceptSignature(accepted)
        result(nil)
    }
    
    private func submitAuthCode(authCode: String, result: @escaping FlutterResult) {
        client.submitAuthCode(authCode, completion: { (result) in
                              print(String(format: "Valid format: %@)", result?.isValidFormat ?? false))
            print(String(format: "Message: %@", result?.message ?? "-"))
                          })
        result(nil)
    }
    
    private func cancelTransaction(result: @escaping FlutterResult) {
        client.cancelTransaction()
        result(nil)
    }
    
    private func initiateCashoutOnlyTx(posRefId: String, amountCents: Int, result: @escaping FlutterResult) {
        client.initiateCashoutOnlyTx(posRefId, amountCents: amountCents, completion: printResult)
        result(nil)
    }
    
    private func initiateMotoPurchaseTx(posRefId: String, amountCents: Int, result: @escaping FlutterResult) {
        client.initiateMotoPurchaseTx(posRefId, amountCents: amountCents, completion: printResult)
        result(nil)
    }
    
    private func initiateSettleTx(id: String, result: @escaping FlutterResult) {
        client.initiateSettleTx(id, completion: printResult)
        result(nil)
    }
    
    private func initiateSettlementEnquiry(posRefId: String, result: @escaping FlutterResult) {
        client.initiateSettlementEnquiry(posRefId, completion: printResult)
        result(nil)
    }
    
    private func initiateGetLastTx(result: @escaping FlutterResult) {
        client.initiateGetLastTx(completion: printResult)
        result(nil)
    }
    
    private func dispose(result: @escaping FlutterResult) {
        result(nil)
    }
    
    private func setPromptForCustomerCopyOnEftpos(promptForCustomerCopyOnEftpos: Bool, result: @escaping FlutterResult) {
        client.config.promptForCustomerCopyOnEftpos = promptForCustomerCopyOnEftpos
        result(nil)
    }
    
    private func setSignatureFlowOnEftpos(signatureFlowOnEftpos: Bool, result: @escaping FlutterResult) {
        client.config.signatureFlowOnEftpos = signatureFlowOnEftpos
        result(nil)
    }
    
    private func setPrintMerchantCopy(printMerchantCopy: Bool, result: @escaping FlutterResult) {
        client.config.printMerchantCopy = printMerchantCopy
        result(nil)
    }
    
    
    
    
    private func mapSecrets(obj: SPISecrets) -> [String: Any] {
        var map:[String: Any] = [:]
        map["encKey"] = obj.encKey
        map["hmacKey"] = obj.hmacKey
        return map
    }
    
    private func mapPairingFlowState(state: SPIPairingFlowState) -> [String: Any] {
        var map:[String: Any] = [:]
        map["message"] = state.message
        map["awaitingCheckFromEftpos"] = state.isAwaitingCheckFromEftpos
        map["awaitingCheckFromPos"] = state.isAwaitingCheckFromPos
        map["confirmationCode"] = state.confirmationCode
        map["finished"] = state.isFinished
        map["successful"] = state.isSuccessful
        return map
    }
    
    private func mapTransactionState(state: SPITransactionFlowState) -> [String: Any] {
        var map:[String: Any] = [:]
        map["posRefId"] = state.posRefId
        map["type"] = state.type.name
        map["displayMessage"] = state.displayMessage
        map["amountCents"] = state.amountCents
        map["requestSent"] = state.isRequestSent
        map["requestTime"] = stringFromDate(state.requestDate)
        map["lastStateRequestTime"] = stringFromDate(state.lastStateRequestTime)
        map["attemptingToCancel"] = state.isAttemptingToCancel
        map["awaitingSignatureCheck"] = state.isAwaitingSignatureCheck
        map["awaitingPhoneForAuth"] = state.isAwaitingPhoneForAuth
        map["finished"] = state.isFinished
        map["success"] = mapTxStateSuccess(state.successState)
        map["response"] = state.response != nil ? mapMessage(message: state.response) : nil
        map["signatureRequiredMessage"] = state.signatureRequiredMessage != nil ? mapSignatureRequest(obj: state.signatureRequiredMessage) : nil
        map["phoneForAuthRequiredMessage"] = state.phoneForAuthRequiredMessage != nil ? mapPhoneForAuthRequired(obj: state.phoneForAuthRequiredMessage) : nil
        map["cancelAttemptTime"] = state.cancelAttemptTime != nil ? stringFromDate(state.cancelAttemptTime) : nil
        map["request"] = state.request != nil ? mapMessage(message: state.request) : nil
        map["awaitingGltResponse"] = state.isAwaitingGltResponse
        
        return map
    }
    
    private func mapSpiConfig(obj: SPIConfig) -> [String: Bool] {
        var map:[String: Bool] = [:]
        map["promptForCustomerCopyOnEftpos"] = obj.promptForCustomerCopyOnEftpos
        map["signatureFlowOnEftpos"] = obj.signatureFlowOnEftpos
        return map
    }
    
    private func mapMessage(message: SPIMessage) -> [String: Any] {
        var map:[String: Any] = [:]
        map["id"] = message.mid
        map["event"] = message.eventName
        map["data"] = message.data
        return map
    }
    
    private func mapSignatureRequest(obj: SPISignatureRequired) -> [String: Any] {
        var map:[String: Any] = [:]
        map["requestId"] = obj.requestId
        map["posRefId"] = obj.posRefId
        map["receiptToSign"] = obj.getMerchantReceipt()
        return map
    }
    
    private func mapPhoneForAuthRequired(obj: SPIPhoneForAuthRequired) -> [String: Any] {
        var map:[String: Any] = [:]
        map["requestId"] = obj.requestId
        map["posRefId"] = obj.posRefId
        map["phoneNumber"] = obj.getPhoneNumber()
        map["merchantId"] = obj.getMerchantId()
        return map
    }
    
    private func stringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy HH:mm" //yyyy
        return formatter.string(from: date)
    }
    
    private func mapTxStateSuccess(_ success: SPIMessageSuccessState) -> String {
        switch success {
        case SPIMessageSuccessState.success:
            return "SUCCESS"
        case SPIMessageSuccessState.failed:
            return "FAILED"
        default:
            return "UNKNOWN"
        }
    }
    
    func printResult(result: SPIInitiateTxResult?) {
        DispatchQueue.main.async {
            SPILogMsg(result?.message)
        }
    }

}
