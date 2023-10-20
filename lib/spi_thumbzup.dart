import 'package:flutter/services.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi/flutter_spi_platform.dart';

class SpiThumbzup implements FlutterSpiPlatform {
  static const String appUrl = "payment.thumbzup.com";
  static const String appClass = "payment.thumbzup.com.IntentActivity";

  static const MethodChannel _channel = MethodChannel('thumbzup');

  @override
  Future<void> initiatePurchaseTx(String posRefId, int purchaseAmount,
      int tipAmount, int cashoutAmount, bool promptForCashout) async {
    // TODO: implement initiatePurchaseTx
    await _channel.invokeMethod("initiatePurchaseTx", {
      "posRefId": posRefId,
      "purchaseAmount": purchaseAmount,
      "tipAmount": tipAmount,
      "cashoutAmount": cashoutAmount,
      "promptForCashout": promptForCashout,
    });
  }

  @override
  Future<void> initiateRefundTx(String posRefId, int refundAmount) {
    // TODO: implement initiateRefundTx
    throw UnimplementedError();
  }

  @override
  Future<void> acceptSignature(bool accepted) {
    // TODO: implement acceptSignature
    throw UnimplementedError();
  }

  @override
  Future<void> ackFlowEndedAndBackToIdle() {
    // TODO: implement ackFlowEndedAndBackToIdle
    throw UnimplementedError();
  }

  @override
  Future<void> cancelTransaction() {
    // TODO: implement cancelTransaction
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() {
    // TODO: implement dispose
    throw UnimplementedError();
  }

  @override
  // TODO: implement getConfig
  Future<Map<String, bool>> get getConfig => throw UnimplementedError();

  @override
  // TODO: implement getCurrentFlow
  Future<String> get getCurrentFlow => throw UnimplementedError();

  @override
  // TODO: implement getCurrentPairingFlowState
  Future<String> get getCurrentPairingFlowState => throw UnimplementedError();

  @override
  // TODO: implement getCurrentStatus
  Future<String> get getCurrentStatus => throw UnimplementedError();

  @override
  // TODO: implement getCurrentTxFlowState
  Future<String> get getCurrentTxFlowState => throw UnimplementedError();

  @override
  // TODO: implement getDeviceSN
  Future<String> get getDeviceSN => throw UnimplementedError();

  @override
  Future<List<Tenant>> getTenantsList(String apiKey,
      {String countryCode = "AU"}) {
    // TODO: implement getTenantsList
    throw UnimplementedError();
  }

  @override
  // TODO: implement getVersion
  Future<String> get getVersion => throw UnimplementedError();

  @override
  Future<void> init(String posId, String serialNumber, String eftposAddress,
      String apiKey, String tenantCode,
      {Map<String, String>? secrets, String? spiType}) async {
    // TODO: implement init
    await _channel.invokeMethod("init");
  }

  @override
  Future<void> initiateCashoutOnlyTx(String posRefId, int amountCents) {
    // TODO: implement initiateCashoutOnlyTx
    throw UnimplementedError();
  }

  @override
  Future<void> initiateGetLastTx() {
    // TODO: implement initiateGetLastTx
    throw UnimplementedError();
  }

  @override
  Future<void> initiateMotoPurchaseTx(String posRefId, int amountCents) {
    // TODO: implement initiateMotoPurchaseTx
    throw UnimplementedError();
  }

  @override
  Future<void> initiateSettleTx(String id) {
    // TODO: implement initiateSettleTx
    throw UnimplementedError();
  }

  @override
  Future<void> initiateSettlementEnquiry(String posRefId) {
    // TODO: implement initiateSettlementEnquiry
    throw UnimplementedError();
  }

  @override
  Future<void> pair() {
    // TODO: implement pair
    throw UnimplementedError();
  }

  @override
  Future<void> pairingCancel() {
    // TODO: implement pairingCancel
    throw UnimplementedError();
  }

  @override
  Future<void> pairingConfirmCode() {
    // TODO: implement pairingConfirmCode
    throw UnimplementedError();
  }

  @override
  Future<void> setEftposAddress(String address) {
    // TODO: implement setEftposAddress
    throw UnimplementedError();
  }

  @override
  Future<void> setPosId(String posId) {
    // TODO: implement setPosId
    throw UnimplementedError();
  }

  @override
  Future<void> setPosInfo(String posVendorId, String posVersion) {
    // TODO: implement setPosInfo
    throw UnimplementedError();
  }

  @override
  Future<void> setPrintMerchantCopy(bool printMerchantCopy) {
    // TODO: implement setPrintMerchantCopy
    throw UnimplementedError();
  }

  @override
  Future<void> setPromptForCustomerCopyOnEftpos(
      bool promptForCustomerCopyOnEftpos) {
    // TODO: implement setPromptForCustomerCopyOnEftpos
    throw UnimplementedError();
  }

  @override
  Future<void> setSerialNumber(String serialNumber) {
    // TODO: implement setSerialNumber
    throw UnimplementedError();
  }

  @override
  Future<void> setSignatureFlowOnEftpos(bool signatureFlowOnEftpos) {
    // TODO: implement setSignatureFlowOnEftpos
    throw UnimplementedError();
  }

  @override
  Future<void> setTenantCode(String tenantCode) {
    // TODO: implement setTenantCode
    throw UnimplementedError();
  }

  @override
  Future<void> start() async {
    // TODO: implement start
    await _channel.invokeMethod("start");
  }

  @override
  Future<void> submitAuthCode(String authCode) {
    // TODO: implement submitAuthCode
    throw UnimplementedError();
  }

  @override
  Future<void> unpair() {
    // TODO: implement unpair
    throw UnimplementedError();
  }

  @override
  void handleMethodCall(dynamic cb) {
    _channel.setMethodCallHandler(cb);
  }
}
