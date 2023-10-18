import 'dart:async';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spi/flutter_spi_platform.dart';
import 'package:flutter_spi/spi_method_channel.dart';
import 'package:flutter_spi/spi_thumbzup.dart';

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

class Tenant {
  String code;
  String name;

  Tenant({
    required this.code,
    required this.name,
  });

  factory Tenant.fromMap(Map<dynamic, dynamic> obj) {
    return Tenant(
      code: obj['code'],
      name: obj['name'],
    );
  }

  Map<String, String> toJSON() {
    return <String, String>{
      'code': code,
      'name': name,
    };
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

class FlutterSpi implements FlutterSpiPlatform {
  static FlutterSpiPlatform flutterSpi = SpiMethodChannel();

  
  @override
  void handleMethodCall(cb) {
    flutterSpi.handleMethodCall(cb);
  }

  @override
  Future<void> init(String posId, String serialNumber, String eftposAddress,
      String apiKey, String tenantCode,
      {Map<String, String>? secrets, String? spiType}) async {
    if (spiType == "THUMBZUP") {
      flutterSpi = SpiThumbzup();
    }
    flutterSpi.init(posId, serialNumber, eftposAddress, apiKey, tenantCode,
        secrets: secrets);
  }

  @override
  Future<void> start() async {
    flutterSpi.start();
  }

  @override
  Future<void> setPosId(String posId) async {
    flutterSpi.setPosId(posId);
  }

  @override
  Future<void> setSerialNumber(String serialNumber) async {
    flutterSpi.setSerialNumber(serialNumber);
  }

  @override
  Future<void> setEftposAddress(String address) async {
    flutterSpi.setEftposAddress(address);
  }

  @override
  Future<void> setTenantCode(String tenantCode) async {
    flutterSpi.setTenantCode(tenantCode);
  }

  @override
  Future<void> setPosInfo(String posVendorId, String posVersion) async {
    flutterSpi.setPosInfo(posVendorId, posVersion);
  }

  @override
  Future<List<Tenant>> getTenantsList(String apiKey,
      {String countryCode = "AU"}) async {
    return flutterSpi.getTenantsList(apiKey);
  }

  @override
  Future<String> get getDeviceSN async {
    return flutterSpi.getDeviceSN;
  }

  @override
  Future<String> get getVersion async {
    return flutterSpi.getVersion;
  }

  @override
  Future<String> get getCurrentStatus async {
    return flutterSpi.getCurrentStatus;
  }

  @override
  Future<String> get getCurrentFlow async {
    return flutterSpi.getCurrentFlow;
  }

  @override
  Future<String> get getCurrentPairingFlowState async {
    return flutterSpi.getCurrentPairingFlowState;
  }

  @override
  Future<String> get getCurrentTxFlowState async {
    return flutterSpi.getCurrentTxFlowState;
  }

  @override
  Future<Map<String, bool>> get getConfig async {
    return flutterSpi.getConfig;
  }

  @override
  Future<void> ackFlowEndedAndBackToIdle() async {
    flutterSpi.ackFlowEndedAndBackToIdle();
  }

  @override
  Future<void> pair() async {
    flutterSpi.pair();
  }

  @override
  Future<void> pairingConfirmCode() async {
    flutterSpi.pairingConfirmCode();
  }

  @override
  Future<void> pairingCancel() async {
    flutterSpi.pairingCancel();
  }

  @override
  Future<void> unpair() async {
    flutterSpi.unpair();
  }

  @override
  Future<void> initiatePurchaseTx(String posRefId, int purchaseAmount,
      int tipAmount, int cashoutAmount, bool promptForCashout) async {
        flutterSpi.initiatePurchaseTx(posRefId, purchaseAmount, tipAmount, cashoutAmount, promptForCashout);
      }

  @override
  Future<void> initiateRefundTx(String posRefId, int refundAmount) async {}

  @override
  Future<void> acceptSignature(bool accepted) async {}

  @override
  Future<void> submitAuthCode(String authCode) async {}

  @override
  Future<void> cancelTransaction() async {}

  @override
  Future<void> initiateCashoutOnlyTx(String posRefId, int amountCents) async {}

  @override
  Future<void> initiateMotoPurchaseTx(String posRefId, int amountCents) async {}

  @override
  Future<void> initiateSettleTx(String id) async {}

  @override
  Future<void> initiateSettlementEnquiry(String posRefId) async {}

  @override
  Future<void> initiateGetLastTx() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> setPromptForCustomerCopyOnEftpos(
      bool promptForCustomerCopyOnEftpos) async {}

  @override
  Future<void> setSignatureFlowOnEftpos(bool signatureFlowOnEftpos) async {}

  @override
  Future<void> setPrintMerchantCopy(bool printMerchantCopy) async {}
  
}
