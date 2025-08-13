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
  }) async {
    throw UnimplementedError();
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
  Future<List<Tenant>> getTenantsList(String apiKey, {String countryCode = "AU"}) async{
    // no need
    return [];
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
  Future<void> setPromptForCustomerCopyOnEftpos(bool promptForCustomerCopyOnEftpos) async{
    // no need
    return;
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
  Future<void> setSignatureFlowOnEftpos(bool signatureFlowOnEftpos) async{
    // no need
    return;
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
  Future<void> unpair() {
    // TODO: implement unpair
    throw UnimplementedError();
  }
  

 // TIM API 

  @override
  Future<void> timApiInit({
    String? eftposAddress,
    String? posId,
    int? port,
    bool enablePrinting = false,
  }) async {
    try {
      await _channel.invokeMethod('timApiInit', {
        'eftposAddress': eftposAddress ??'10.0.2.2',//192.168.020.009
        'posId': posId ?? '12345678',
        'port': port ?? 7784,
        'enablePrinting': enablePrinting,
      });
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> timApiConnect() async {
    try {
      await _channel.invokeMethod('timApiConnect');
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> timApiLogin() async { //for example
    try {
      await _channel.invokeMethod('timApiLogin');
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> timApiActivate() async { //for example
    try {
      await _channel.invokeMethod('timApiActivate');
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> timApiCharge(double amount) async {
    try {
      await _channel.invokeMethod('timApiStartTransaction', {
        'posRefId': 'test_transaction_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
      });
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> timApiRefund(double amount) async { //for standard refund
    try {
      await _channel.invokeMethod('timApiDoRefund', {
        'posRefId': 'test_refund_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
      });
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> timApiRefRefund({
    required double amount,
    required String sixTrxRefNum,
  }) async { //for reference refund
    try {
      await _channel.invokeMethod('timApiDoRefRefund', {
        'posRefId': 'test_refund_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount, 
        'sixTrxRefNum': sixTrxRefNum, // Six transaction reference number
      });
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> timApiBalance() async {
    try {
      await _channel.invokeMethod('timApiDoBalance', {
        'posRefId': 'test_Balance_${DateTime.now().millisecondsSinceEpoch}',
      });
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<void> timApiReversal({String? transSeq}) async {
    try {
      await _channel.invokeMethod('timApiDoReversal', {
        'posRefId': 'test_reversal_${DateTime.now().millisecondsSinceEpoch}',
        'transSeq': transSeq,
      });
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> getTerminalStatus() async {
    try {
      return (await _channel.invokeMethod<String>('getTerminalStatus')) ?? "Unknown";
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> timApiDeactivate() async {
    try {
      await _channel.invokeMethod('timApiDeactivate');
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> timApiDisconnect() async{
    try {
      await _channel.invokeMethod('timApiDisconnect');
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> timApiLogout()async {
    try {
      await _channel.invokeMethod('timApiLogout');
    } on PlatformException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
