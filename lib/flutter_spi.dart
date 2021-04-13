import 'dart:async';

import 'package:flutter/services.dart';

enum NativeMethodCalls {
  statusChanged,
  pairingFlowStateChanged,
  txFlowStateChanged,
  secretsChanged,
  deviceAddressChanged,
}

class FlutterSpi {
  static const MethodChannel _channel = const MethodChannel('flutter_spi');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /*
    method:
    statusChanged,
    pairingFlowStateChanged,
    txFlowStateChanged,
    secretsChanged,
    deviceAddressChanged, 
   */
  static void handleMethodCall(Function cb) {
    _channel.setMethodCallHandler(cb);
  }

  static Future<void> init(String posId, String sn, String eftposAddress,
      {Map<String, String> secrets}) async {
    await _channel.invokeMethod('init', {
      "posId": posId,
      "sn": sn,
      "eftposAddress": eftposAddress,
      "secrets": secrets,
    });
  }

  static Future<void> start() async {
    await _channel.invokeMethod('start');
  }

  static Future<void> setAcquirerCode(String acquirerCode) async {
    await _channel
        .invokeMethod('setAcquirerCode', {"acquirerCode": acquirerCode});
  }

  static Future<void> setDeviceApiKey(String deviceApiKey) async {
    await _channel
        .invokeMethod('setDeviceApiKey', {"deviceApiKey": deviceApiKey});
  }

  static Future<void> setSerialNumber(String serialNumber) async {
    await _channel
        .invokeMethod('setSerialNumber', {"serialNumber": serialNumber});
  }

  static Future<String> get getSerialNumber async {
    return await _channel.invokeMethod('getSerialNumber');
  }

  static Future<void> setAutoAddressResolution(
      bool autoAddressResolutionEnable) async {
    await _channel.invokeMethod('setAutoAddressResolution',
        {"autoAddressResolutionEnable": autoAddressResolutionEnable});
  }

  static Future<bool> get isAutoAddressResolutionEnabled async {
    final bool result =
        await _channel.invokeMethod('isAutoAddressResolutionEnabled');
    return result;
  }

  static Future<void> setTestMode(bool testMode) async {
    await _channel.invokeMethod('setTestMode', {"testMode": testMode});
  }

  static Future<void> setPosId(String posId) async {
    await _channel.invokeMethod('setPosId', {"posId": posId});
  }

  static Future<void> setEftposAddress(String address) async {
    await _channel
        .invokeMethod('sesetEftposAddressPosId', {"address": address});
  }

  static Future<void> setPosInfo(String posVendorId, String posVersion) async {
    await _channel.invokeMethod(
        'setPosInfo', {"posVendorId": posVendorId, "posVersion": posVersion});
  }

  static Future<String> get getVersion async {
    final String spiVersion = await _channel.invokeMethod('getVersion');
    return spiVersion;
  }

  static Future<String> get getCurrentStatus async {
    final String status = await _channel.invokeMethod('getCurrentStatus');
    return status;
  }

  static Future<String> get getCurrentFlow async {
    final String flowState = await _channel.invokeMethod('getCurrentFlow');
    return flowState;
  }

  static Future<String> get getCurrentPairingFlowState async {
    final String flowState =
        await _channel.invokeMethod('getCurrentPairingFlowState');
    return flowState;
  }

  static Future<String> get getCurrentTxFlowState async {
    final String flowState =
        await _channel.invokeMethod('getCurrentTxFlowState');
    return flowState;
  }

  static Future<Map<String, bool>> get getConfig async {
    final Map<String, bool> config = await _channel.invokeMethod('getConfig');
    return config;
  }

  static Future<void> ackFlowEndedAndBackToIdle() async {
    await _channel.invokeMethod('ackFlowEndedAndBackToIdle');
  }

  static Future<void> pair() async {
    await _channel.invokeMethod('pair');
  }

  static Future<void> pairingConfirmCode() async {
    await _channel.invokeMethod('pairingConfirmCode');
  }

  static Future<void> pairingCancel() async {
    await _channel.invokeMethod('pairingCancel');
  }

  static Future<void> unpair() async {
    await _channel.invokeMethod('unpair');
  }

  static Future<void> initiatePurchaseTx(String posRefId, int purchaseAmount,
      int tipAmount, int cashoutAmount, bool promptForCashout) async {
    await _channel.invokeMethod('initiatePurchaseTx', {
      "posRefId": posRefId,
      "purchaseAmount": purchaseAmount,
      "tipAmount": tipAmount,
      "cashoutAmount": cashoutAmount,
      "promptForCashout": promptForCashout,
    });
  }

  static Future<void> initiateRefundTx(
      String posRefId, int refundAmount) async {
    await _channel.invokeMethod('initiateRefundTx', {
      "posRefId": posRefId,
      "refundAmount": refundAmount,
    });
  }

  static Future<void> acceptSignature(bool accepted) async {
    await _channel.invokeMethod('acceptSignature', {
      "accepted": accepted,
    });
  }

  static Future<void> submitAuthCode(String authCode) async {
    await _channel.invokeMethod('submitAuthCode', {
      "authCode": authCode,
    });
  }

  static Future<void> cancelTransaction() async {
    await _channel.invokeMethod('cancelTransaction');
  }

  static Future<void> initiateCashoutOnlyTx(
      String posRefId, int amountCents) async {
    await _channel.invokeMethod('initiateCashoutOnlyTx', {
      "posRefId": posRefId,
      "amountCents": amountCents,
    });
  }

  static Future<void> initiateMotoPurchaseTx(
      String posRefId, int amountCents) async {
    await _channel.invokeMethod('initiateMotoPurchaseTx', {
      "posRefId": posRefId,
      "amountCents": amountCents,
    });
  }

  static Future<void> initiateSettleTx(String id) async {
    await _channel.invokeMethod('initiateSettleTx', {
      "id": id,
    });
  }

  static Future<void> initiateSettlementEnquiry(String posRefId) async {
    await _channel.invokeMethod('initiateSettlementEnquiry', {
      "posRefId": posRefId,
    });
  }

  static Future<void> initiateGetLastTx() async {
    await _channel.invokeMethod('initiateGetLastTx');
  }

  static Future<void> dispose() async {
    await _channel.invokeMethod('dispose');
  }

  static Future<void> setPromptForCustomerCopyOnEftpos(
      bool promptForCustomerCopyOnEftpos) async {
    await _channel.invokeMethod('setPromptForCustomerCopyOnEftpos', {
      "promptForCustomerCopyOnEftpos": promptForCustomerCopyOnEftpos,
    });
  }

  static Future<void> setSignatureFlowOnEftpos(
      bool signatureFlowOnEftpos) async {
    await _channel.invokeMethod('setSignatureFlowOnEftpos', {
      "signatureFlowOnEftpos": signatureFlowOnEftpos,
    });
  }

  static Future<void> setPrintMerchantCopy(bool printMerchantCopy) async {
    await _channel.invokeMethod('setPrintMerchantCopy', {
      "printMerchantCopy": printMerchantCopy,
    });
  }
}
