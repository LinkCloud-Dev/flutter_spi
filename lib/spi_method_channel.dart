import 'package:flutter/services.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi/flutter_spi_platform.dart';

class SpiMethodChannel implements FlutterSpiPlatform {
  static const MethodChannel _channel = MethodChannel('flutter_spi');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  @override
  void handleMethodCall(dynamic cb) {
    _channel.setMethodCallHandler(cb);
  }

  @override
  Future<void> init(
      {String? posId,
      String? serialNumber,
      String? eftposAddress,
      String? apiKey,
      String? tenantCode,
      Map<String, String>? secrets,
      String? spiType,
      String? appKey,
      String? merchantId,
      String username = "default"}) async {
    await _channel.invokeMethod('init', {
      "posId": posId,
      "serialNumber": serialNumber,
      "eftposAddress": eftposAddress,
      "apiKey": apiKey,
      "tenantCode": tenantCode,
      "secrets": secrets,
    });
  }

  @override
  Future<void> start() async {
    await _channel.invokeMethod('start');
  }

  @override
  Future<void> setPosId(String posId) async {
    await _channel.invokeMethod('setPosId', {"posId": posId});
  }

  @override
  Future<void> setSerialNumber(String serialNumber) async {
    await _channel
        .invokeMethod('setSerialNumber', {"serialNumber": serialNumber});
  }

  @override
  Future<void> setEftposAddress(String address) async {
    await _channel.invokeMethod('setEftposAddress', {"address": address});
  }

  @override
  Future<void> setTenantCode(String tenantCode) async {
    await _channel.invokeMethod('setTenantCode', {"tenantCode": tenantCode});
  }

  @override
  Future<void> setPosInfo(String posVendorId, String posVersion) async {
    await _channel.invokeMethod(
        'setPosInfo', {"posVendorId": posVendorId, "posVersion": posVersion});
  }

  @override
  Future<List<Tenant>> getTenantsList(String apiKey,
      {String countryCode = "AU"}) async {
    final List tenants = await _channel.invokeMethod(
        'getTenantsList', {"apiKey": apiKey, "countryCode": countryCode});
    List<Tenant> tenantsList = tenants.map((e) => Tenant.fromMap(e)).toList();
    return tenantsList;
  }

  @override
  Future<String> get getDeviceSN async {
    final String sn = await _channel.invokeMethod('getDeviceSN');
    return sn;
  }

  @override
  Future<String> get getVersion async {
    final String spiVersion = await _channel.invokeMethod('getVersion');
    return spiVersion;
  }

  @override
  Future<String> get getCurrentStatus async {
    final String status = await _channel.invokeMethod('getCurrentStatus');
    return status;
  }

  @override
  Future<String> get getCurrentFlow async {
    final String flowState = await _channel.invokeMethod('getCurrentFlow');
    return flowState;
  }

  @override
  Future<String> get getCurrentPairingFlowState async {
    final String flowState =
        await _channel.invokeMethod('getCurrentPairingFlowState');
    return flowState;
  }

  @override
  Future<String> get getCurrentTxFlowState async {
    final String flowState =
        await _channel.invokeMethod('getCurrentTxFlowState');
    return flowState;
  }

  @override
  Future<Map<String, bool>> get getConfig async {
    final Map<String, bool> config = await _channel.invokeMethod('getConfig');
    return config;
  }

  @override
  Future<void> ackFlowEndedAndBackToIdle() async {
    await _channel.invokeMethod('ackFlowEndedAndBackToIdle');
  }

  @override
  Future<void> pair() async {
    await _channel.invokeMethod('pair');
  }

  @override
  Future<void> pairingConfirmCode() async {
    await _channel.invokeMethod('pairingConfirmCode');
  }

  @override
  Future<void> pairingCancel() async {
    await _channel.invokeMethod('pairingCancel');
  }

  @override
  Future<void> unpair() async {
    await _channel.invokeMethod('unpair');
  }

  @override
  Future<void> initiatePurchaseTx(String posRefId, int purchaseAmount,
      int tipAmount, int cashoutAmount, bool promptForCashout) async {
    await _channel.invokeMethod('initiatePurchaseTx', {
      "posRefId": posRefId,
      "purchaseAmount": purchaseAmount,
      "tipAmount": tipAmount,
      "cashoutAmount": cashoutAmount,
      "promptForCashout": promptForCashout,
    });
  }

  @override
  Future<void> initiateRefundTx(String posRefId, int refundAmount) async {
    await _channel.invokeMethod('initiateRefundTx', {
      "posRefId": posRefId,
      "refundAmount": refundAmount,
    });
  }

  @override
  Future<void> acceptSignature(bool accepted) async {
    await _channel.invokeMethod('acceptSignature', {
      "accepted": accepted,
    });
  }

  @override
  Future<void> submitAuthCode(String authCode) async {
    await _channel.invokeMethod('submitAuthCode', {
      "authCode": authCode,
    });
  }

  @override
  Future<void> cancelTransaction() async {
    await _channel.invokeMethod('cancelTransaction');
  }

  @override
  Future<void> initiateCashoutOnlyTx(String posRefId, int amountCents) async {
    await _channel.invokeMethod('initiateCashoutOnlyTx', {
      "posRefId": posRefId,
      "amountCents": amountCents,
    });
  }

  @override
  Future<void> initiateMotoPurchaseTx(String posRefId, int amountCents) async {
    await _channel.invokeMethod('initiateMotoPurchaseTx', {
      "posRefId": posRefId,
      "amountCents": amountCents,
    });
  }

  @override
  Future<void> initiateSettleTx(String id) async {
    await _channel.invokeMethod('initiateSettleTx', {
      "id": id,
    });
  }

  @override
  Future<void> initiateSettlementEnquiry(String posRefId) async {
    await _channel.invokeMethod('initiateSettlementEnquiry', {
      "posRefId": posRefId,
    });
  }

  @override
  Future<void> initiateGetLastTx() async {
    await _channel.invokeMethod('initiateGetLastTx');
  }

  @override
  Future<void> dispose() async {
    await _channel.invokeMethod('dispose');
  }

  @override
  Future<void> setPromptForCustomerCopyOnEftpos(
      bool promptForCustomerCopyOnEftpos) async {
    await _channel.invokeMethod('setPromptForCustomerCopyOnEftpos', {
      "promptForCustomerCopyOnEftpos": promptForCustomerCopyOnEftpos,
    });
  }

  @override
  Future<void> setSignatureFlowOnEftpos(bool signatureFlowOnEftpos) async {
    await _channel.invokeMethod('setSignatureFlowOnEftpos', {
      "signatureFlowOnEftpos": signatureFlowOnEftpos,
    });
  }

  @override
  Future<void> setPrintMerchantCopy(bool printMerchantCopy) async {
    await _channel.invokeMethod('setPrintMerchantCopy', {
      "printMerchantCopy": printMerchantCopy,
    });
  }

  @override
  void setAppKey(String appKey) {
    // NOT NEEDED
  }

  @override
  void setMerchantId(String merchantId) {
    // NOT NEEDED
  }

  @override
  void setSecrets(Map<String, String> secrets) {
    // NOT NEEDED
  }

  @override
  void setUsername(String username) {
    // NOT NEEDED
  }
}
