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
    String? host, // <-- 修改：TIM API 需要 host
    int? port,    // <-- 修改：TIM API 需要 port
    String? sslCertificatePath, // <-- TIM API 需要 cert path
    String? integratorId, // <-- TIM API 需要 integrator ID
    int timeout = 30,
    String? posId,         // no need (for TIM API)
    String? serialNumber,  // no need
    String? eftposAddress, // no need
    String? apiKey,        // no need
    String? tenantCode,    // no need
    Map<String, String>? secrets, // no need
    String? spiType,       // no need
    String? appKey,        // no need
    String? merchantId,    // no need
    String username = "default" // no need
  }) async {
    await _channel.invokeMethod('timApiInit', {
      'host': host,
      'port': port,
      'sslCertificatePath': sslCertificatePath,
      'integratorId': integratorId,
      'timeout': timeout,
    });
  }

  @override
  Future<void> acceptSignature(bool accepted) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> ackFlowEndedAndBackToIdle() {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> cancelTransaction() async {
    await _channel.invokeMethod('timApiCancelTransaction');
  }

  @override
  Future<void> dispose() async {
    await _channel.invokeMethod('timApiDispose');
  }

  @override
  Future<Map<String, bool>> get getConfig => throw UnimplementedError(); // no need

  @override
  Future<String> get getCurrentFlow => throw UnimplementedError(); // no need

  @override
  Future<String> get getCurrentPairingFlowState => throw UnimplementedError(); // no need

  @override
  Future<String> get getCurrentStatus async {
    return (await _channel.invokeMethod<String>('timApiGetTerminalStatus')) ?? "Unknown";
  }

  @override
  Future<String> get getCurrentTxFlowState => throw UnimplementedError(); // no need

  @override
  Future<String> get getDeviceSN => throw UnimplementedError(); // no need

  @override
  Future<List<Tenant>> getTenantsList(String apiKey, {String countryCode = "AU"}) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<String> get getVersion async {
    return (await _channel.invokeMethod<String>('timApiGetVersion')) ?? "Unknown";
  }

  @override
  Future<void> initiateCashoutOnlyTx(String posRefId, int amountCents) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> initiateGetLastTx() async {
    await _channel.invokeMethod('timApiGetLastTransaction');
  }

  @override
  Future<void> initiateMotoPurchaseTx(String posRefId, int amountCents) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> initiatePurchaseTx(
      String posRefId,
      int purchaseAmount,
      int tipAmount,
      int cashoutAmount,
      bool promptForCashout) async {
    // TIM API 建议统一：只有 purchaseAmount
    await _channel.invokeMethod('timApiStartTransaction', {
      'posRefId': posRefId,
      'amount': purchaseAmount,
    });
  }

  @override
  Future<void> initiateRefundTx(String posRefId, int refundAmount) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> initiateSettleTx(String id) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> initiateSettlementEnquiry(String posRefId) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> pair() async{
    await _channel.invokeMethod('timApiPair');
  }

  @override
  Future<void> pairingCancel() {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> pairingConfirmCode() {
    // no need
    throw UnimplementedError();
  }

  @override
  void setAppKey(String appKey) {
    // no need
  }

  @override
  Future<void> setEftposAddress(String address) {
    // no need
    throw UnimplementedError();
  }

  @override
  void setMerchantId(String merchantId) {
    // no need
  }

  @override
  Future<void> setPosId(String posId) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> setPosInfo(String posVendorId, String posVersion) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> setPrintMerchantCopy(bool printMerchantCopy) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> setPromptForCustomerCopyOnEftpos(bool promptForCustomerCopyOnEftpos) {
    // no need
    throw UnimplementedError();
  }

  @override
  void setSecrets(Map<String, String> secrets) {
    // no need
  }

  @override
  Future<void> setSerialNumber(String serialNumber) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> setSignatureFlowOnEftpos(bool signatureFlowOnEftpos) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> setTenantCode(String tenantCode) {
    // no need
    throw UnimplementedError();
  }

  @override
  void setUsername(String username) {
    // no need
  }

  @override
  Future<void> start() async {
    await _channel.invokeMethod('timApiStartListening'); // TIM API 如果有事件监听
  }

  @override
  Future<void> submitAuthCode(String authCode) {
    // no need
    throw UnimplementedError();
  }

  @override
  Future<void> test() async {
    await _channel.invokeMethod('timApiTestConnection');
  }

  @override
  Future<void> unpair() {
    // no need
    throw UnimplementedError();
  }
}
