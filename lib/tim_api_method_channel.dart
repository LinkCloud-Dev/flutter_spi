// lib/timapi/timapi_implementation.dart
import 'package:flutter/services.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi/flutter_spi_platform.dart';

class TimApiMethodChannel implements FlutterSpiPlatform {
  static const MethodChannel _channel = MethodChannel('flutter_spi_timapi');

  @override
  void handleMethodCall(cb) {
    _channel.setMethodCallHandler(cb);
  }

  @override
  Future<void> init({
    String? posId,
    String? serialNumber,
    String? eftposAddress,
    String? apiKey,
    String? tenantCode,
    Map<String, String>? secrets,
    String? spiType,
    String? appKey,
    String? merchantId,
    String username = "default"
  }) async {
    await _channel.invokeMethod('init', {
      'posId': posId,
      'serialNumber': serialNumber,
      'secrets': secrets,
      // Other parameters
    });
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
  Future<List<Tenant>> getTenantsList(String apiKey, {String countryCode = "AU"}) {
    // TODO: implement getTenantsList
    throw UnimplementedError();
  }

  @override
  // TODO: implement getVersion
  Future<String> get getVersion => throw UnimplementedError();

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
  Future<void> initiatePurchaseTx(String posRefId, int purchaseAmount, int tipAmount, int cashoutAmount, bool promptForCashout) {
    // TODO: implement initiatePurchaseTx
    throw UnimplementedError();
  }

  @override
  Future<void> initiateRefundTx(String posRefId, int refundAmount) {
    // TODO: implement initiateRefundTx
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
  void setAppKey(String appKey) {
    // TODO: implement setAppKey
  }

  @override
  Future<void> setEftposAddress(String address) {
    // TODO: implement setEftposAddress
    throw UnimplementedError();
  }

  @override
  void setMerchantId(String merchantId) {
    // TODO: implement setMerchantId
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
  Future<void> setPromptForCustomerCopyOnEftpos(bool promptForCustomerCopyOnEftpos) {
    // TODO: implement setPromptForCustomerCopyOnEftpos
    throw UnimplementedError();
  }

  @override
  void setSecrets(Map<String, String> secrets) {
    // TODO: implement setSecrets
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
  void setUsername(String username) {
    // TODO: implement setUsername
  }

  @override
  Future<void> start() {
    // TODO: implement start
    throw UnimplementedError();
  }

  @override
  Future<void> submitAuthCode(String authCode) {
    // TODO: implement submitAuthCode
    throw UnimplementedError();
  }

  @override
  Future<void> test() {
    // TODO: implement test
    throw UnimplementedError();
  }

  @override
  Future<void> unpair() {
    // TODO: implement unpair
    throw UnimplementedError();
  }

  // Implement other required methods
}