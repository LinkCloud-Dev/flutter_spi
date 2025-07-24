import 'package:flutter/services.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi/flutter_spi_platform.dart';

class TimApiMethodChannel implements FlutterSpiPlatform {
  static const MethodChannel _channel = MethodChannel('flutter_spi_timapi');
  static const EventChannel _eventChannel = EventChannel("flutter_spi_timapi_events");

  @override
  void handleMethodCall(cb) {
    _channel.setMethodCallHandler(cb);
  }

  @override
  Stream<dynamic> get eventStream => _eventChannel.receiveBroadcastStream();

  @override
  Future<void> init({
    int? port,            // tim api port
    String? posId,         // Tim Api intergater id
    String? serialNumber,  // no need
    String? eftposAddress, // tim api Ip
    String? apiKey,        // no need
    String? tenantCode,    // no need
    Map<String, String>? secrets, // no need
    String? spiType,       // no need
    String? appKey,        // no need
    String? merchantId,    // no need
    String username = "default", // no need
    bool enablePrinting = false, // For accreditation - control receipt printing
  }) async {
    await _channel.invokeMethod('timApiInit', {
      'eftposAddress': eftposAddress,
      'posId': posId,
      'port': 7784,
      'enablePrinting': enablePrinting,
    });
  }

  Future<void> timApiStartTransaction(String posRefId, double amount) async {
    await _channel.invokeMethod('timApiStartTransaction', {
      'posRefId': posRefId,
      'amount': amount,
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
    // no need
    throw UnimplementedError();
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
  Future<void> pair() async {
    // For TIM API, use the specific TIM API pairing method
    // await _channel.invokeMethod('timApiPair');
    await _channel.invokeMethod('timApiPair');
  }

  @override
  Future<void> pairingCancel() async {
    // For TIM API, use the specific TIM API pairing cancel method
    await _channel.invokeMethod('timApiPairingCancel');
  }

  @override
  Future<void> pairingConfirmCode() async {
    // For TIM API, use the specific TIM API pairing confirm method
    await _channel.invokeMethod('timApiPairingConfirmCode');
  }

  @override
  void setAppKey(String appKey) {
    // no need
  }

  @override
  Future<void>  setEftposAddress(String address) {
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
    // Call timApiInit with the stored parameters
    await _channel.invokeMethod('timApiInit', {
      'eftposAddress': '172.20.10.2',
      'posId': '25196219',
      'port': 7784,
      'enablePrinting': false, // Disable printing for testing
    });

    await _channel.invokeMethod('timApiStartTransaction', {
      'posRefId': 'test_transaction_${DateTime.now().millisecondsSinceEpoch}',
      'amount': 5000, // Test amount of 10 cents
    });
  }

  @override
  Future<void> unpair() async {
    // For TIM API, use the specific TIM API unpair method
    await _channel.invokeMethod('timApiUnpair');
  }

  // Public method for pairing (timApiInit)
  Future<void> timApiPairing({bool enablePrinting = false}) async { //for example
    await _channel.invokeMethod('timApiInit', {
      'eftposAddress': '192.168.020.011', // 10.0.2.2 or 192.168.020.011 or 192.168.236.212
      'posId': '25196219', //12345678 or 25196219
      'port': 7784, //8115
      'enablePrinting': true, // For credentialing - control receipt printing
    });
  }


  Future<void> timApiConnect() async { //for example
    await _channel.invokeMethod('timApiConnect');

  }
  Future<void> timApiLogin() async { //for example
    await _channel.invokeMethod('timApiLogin');

  }
  Future<void> timApiActivate() async { //for example
    await _channel.invokeMethod('timApiActivate');
  }

  // Public method for charge (timApiStartTransaction)
  Future<void> timApiCharge(double amount) async {
    await _channel.invokeMethod('timApiStartTransaction', {
      'posRefId': 'test_transaction_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
    });
  }

  Future<void> timApiRefund(double amount) async { //for standard refund
    await _channel.invokeMethod('timApiDoRefund', {
      'posRefId': 'test_refund_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
    });
  }

  Future<void> timApiRefRefund() async { //for reference refund //TODO: check with ANZ on needed params
    await _channel.invokeMethod('timApiDoRefRefund', {
      'posRefId': 'test_transaction_${DateTime.now().millisecondsSinceEpoch}',
      'acqTransRef': '0100000000002202', // input org tx ref manually
      'amount': 6000, // Example/test amount must smaller than org tx amount
    });
  }

  Future<void> timApiBalance() async {
    await _channel.invokeMethod('timApiDoBalance', {
      'posRefId': 'test_Balance_${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  Future<void> timApiReversal({String? transSeq}) async {
    await _channel.invokeMethod('timApiDoReversal', {
      'posRefId': 'test_reversal_${DateTime.now().millisecondsSinceEpoch}',
      'transSeq': transSeq,
    });
  }

  /*Future<void> timApiPrint(String ticket) async {
    await _channel.invokeMethod('timApiPrint', {
      'ticket': ticket,
    });
  }*/

}
