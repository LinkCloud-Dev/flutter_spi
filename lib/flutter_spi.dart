import 'dart:async';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';

class SpiMessage {
  String? id;
  String? event;
  Map<dynamic, dynamic>? data;

  SpiMessage({
    required this.id,
    required this.event,
    this.data,
  });

  factory SpiMessage.fromMap(Map<dynamic, dynamic> obj) {
    return SpiMessage(
      id: obj['id'],
      event: obj['event'],
      data: obj['data'],
    );
  }
}

class Secrets {
  String encKey;
  String hmacKey;

  Secrets({
    required this.encKey,
    required this.hmacKey,
  });

  factory Secrets.fromMap(Map<dynamic, dynamic> obj) {
    return Secrets(
      encKey: obj['encKey'],
      hmacKey: obj['hmacKey'],
    );
  }

  Map<String, String> toJSON() {
    return <String, String>{
      'encKey': encKey,
      'hmacKey': hmacKey,
    };
  }
}

class SpiConfig {
  bool promptForCustomerCopyOnEftpos;
  bool signatureFlowOnEftpos;

  SpiConfig({
    this.promptForCustomerCopyOnEftpos = false,
    this.signatureFlowOnEftpos = false,
  });

  factory SpiConfig.fromMap(Map<dynamic, dynamic> obj) {
    return SpiConfig(
      promptForCustomerCopyOnEftpos: obj['epromptForCustomerCopyOnEftposncKey'],
      signatureFlowOnEftpos: obj['signatureFlowOnEftpos'],
    );
  }
}

class SignatureRequired {
  String? requestId;
  String? posRefId;
  String? receiptToSign;

  SignatureRequired({
    required this.requestId,
    required this.posRefId,
    required this.receiptToSign,
  });

  factory SignatureRequired.fromMap(Map<dynamic, dynamic> obj) {
    return SignatureRequired(
      requestId: obj['requestId'],
      posRefId: obj['posRefId'],
      receiptToSign: obj['receiptToSign'],
    );
  }
}

class PhoneForAuthRequired {
  String? requestId;
  String? posRefId;
  String? phoneNumber;
  String? merchantId;

  PhoneForAuthRequired({
    required this.requestId,
    required this.posRefId,
    required this.phoneNumber,
    required this.merchantId,
  });

  factory PhoneForAuthRequired.fromMap(Map<dynamic, dynamic> obj) {
    return PhoneForAuthRequired(
      requestId: obj['requestId'],
      posRefId: obj['posRefId'],
      phoneNumber: obj['phoneNumber'],
      merchantId: obj['merchantId'],
    );
  }
}

class PairingFlowState {
  String? message;
  bool awaitingCheckFromEftpos;
  bool awaitingCheckFromPos;
  String? confirmationCode;
  bool finished;
  bool successful;

  PairingFlowState({
    this.message,
    this.awaitingCheckFromEftpos = false,
    this.awaitingCheckFromPos = false,
    this.confirmationCode,
    this.finished = false,
    this.successful = false,
  });

  factory PairingFlowState.fromMap(Map<dynamic, dynamic> obj) {
    return PairingFlowState(
      message: obj['message'],
      awaitingCheckFromEftpos: obj['awaitingCheckFromEftpos'],
      awaitingCheckFromPos: obj['awaitingCheckFromPos'],
      confirmationCode: obj['confirmationCode'],
      finished: obj['finished'],
      successful: obj['successful'],
    );
  }
}

class TransactionFlowState {
  String posRefId;
  SpiTransactionType type;
  String? displayMessage;
  int amountCents;
  bool? isRequestSent;
  String? requestTime;
  String? lastStateRequestTime;
  bool attemptingToCancel;
  bool awaitingSignatureCheck;
  bool awaitingPhoneForAuth;
  bool finished;
  String? success;
  SpiMessage? response;
  SignatureRequired? signatureRequiredMessage;
  PhoneForAuthRequired? phoneForAuthRequiredMessage;
  String? cancelAttemptTime;
  SpiMessage? request;
  bool awaitingGltResponse;

  TransactionFlowState({
    required this.posRefId,
    required this.type,
    this.displayMessage,
    required this.amountCents,
    this.isRequestSent,
    this.requestTime,
    this.lastStateRequestTime,
    this.attemptingToCancel = false,
    this.awaitingSignatureCheck = false,
    this.awaitingPhoneForAuth = false,
    this.finished = false,
    this.success,
    this.response,
    this.signatureRequiredMessage,
    this.phoneForAuthRequiredMessage,
    this.cancelAttemptTime,
    this.request,
    this.awaitingGltResponse = false,
  });

  factory TransactionFlowState.fromMap(Map<dynamic, dynamic> obj) {
    return TransactionFlowState(
      posRefId: obj['posRefId'],
      type: EnumToString.fromString(SpiTransactionType.values, obj['type'])!,
      displayMessage: obj['displayMessage'],
      amountCents: obj['amountCents'],
      isRequestSent: obj['isRequestSent'],
      requestTime: obj['requestTime'],
      lastStateRequestTime: obj['lastStateRequestTime'],
      attemptingToCancel: obj['attemptingToCancel'],
      awaitingSignatureCheck: obj['awaitingSignatureCheck'],
      awaitingPhoneForAuth: obj['awaitingPhoneForAuth'],
      finished: obj['finished'],
      success: obj['success'],
      response:
          obj['response'] != null ? SpiMessage.fromMap(obj['response']) : null,
      signatureRequiredMessage: obj['signatureRequiredMessage'] != null
          ? SignatureRequired.fromMap(obj['signatureRequiredMessage'])
          : null,
      phoneForAuthRequiredMessage: obj['phoneForAuthRequiredMessage'] != null
          ? PhoneForAuthRequired.fromMap(obj['phoneForAuthRequiredMessage'])
          : null,
      cancelAttemptTime: obj['cancelAttemptTime'],
      request:
          obj['request'] != null ? SpiMessage.fromMap(obj['request']) : null,
      awaitingGltResponse: obj['awaitingGltResponse'],
    );
  }
}

enum SpiStatus {
  UNPAIRED,
  PAIRED_CONNECTING,
  PAIRED_CONNECTED,
}

enum SpiFlow {
  IDLE,
  PAIRING,
  TRANSACTION,
}

enum SpiTransactionType {
  PURCHASE,
  REFUND,
  CASHOUT_ONLY,
  MOTO,
  SETTLE,
  SETTLEMENT_ENQUIRY,
  GET_LAST_TRANSACTION,
  PREAUTH,
  ACCOUNT_VERIFY
}

enum SpiMethodCallEvents {
  statusChanged,
  pairingFlowStateChanged,
  txFlowStateChanged,
  secretsChanged,
}

class FlutterSpi {
  static const MethodChannel _channel = const MethodChannel('flutter_spi');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static void handleMethodCall(dynamic cb) {
    _channel.setMethodCallHandler(cb);
  }

  static Future<void> init(String posId, String serialNumber, String eftposAddress, 
      {Map<String, String>? secrets}) async {
    await _channel.invokeMethod('init', {
      "posId": posId,
      "serialNumber": serialNumber,
      "eftposAddress": eftposAddress,
      "secrets": secrets,
    });
  }

  static Future<void> start() async {
    await _channel.invokeMethod('start');
  }

  static Future<void> setPosId(String posId) async {
    await _channel.invokeMethod('setPosId', {"posId": posId});
  }

  static Future<void> setSerialNumber(String serialNumber) async {
    await _channel.invokeMethod('setSerialNumber', {"serialNumber": serialNumber});
  }

  static Future<void> setEftposAddress(String address) async {
    await _channel.invokeMethod('setEftposAddress', {"address": address});
  }

  static Future<void> setPosInfo(String posVendorId, String posVersion) async {
    await _channel.invokeMethod(
        'setPosInfo', {"posVendorId": posVendorId, "posVersion": posVersion});
  }

  static Future<String> get getDeviceSN async {
    final String sn = await _channel.invokeMethod('getDeviceSN');
    return sn;
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
