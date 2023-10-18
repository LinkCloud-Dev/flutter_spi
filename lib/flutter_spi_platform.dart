import 'package:flutter_spi/flutter_spi.dart';

abstract class FlutterSpiPlatform {

  void handleMethodCall(dynamic cb);

  Future<void> init(String posId, String serialNumber, String eftposAddress, String apiKey,
      String tenantCode,
      {Map<String, String>? secrets, String? spiType});

  Future<void> start();

  Future<void> setPosId(String posId);

  Future<void> setSerialNumber(String serialNumber);

  Future<void> setEftposAddress(String address);

  Future<void> setTenantCode(String tenantCode);

  Future<void> setPosInfo(String posVendorId, String posVersion);

  Future<List<Tenant>> getTenantsList(String apiKey,
      {String countryCode = "AU"});

  Future<String> get getDeviceSN;

  Future<String> get getVersion;

  Future<String> get getCurrentStatus;

  Future<String> get getCurrentFlow;

  Future<String> get getCurrentPairingFlowState;

  Future<String> get getCurrentTxFlowState;

  Future<Map<String, bool>> get getConfig;

  Future<void> ackFlowEndedAndBackToIdle();

  Future<void> pair();

  Future<void> pairingConfirmCode();

  Future<void> pairingCancel();

  Future<void> unpair();

  Future<void> initiatePurchaseTx(String posRefId, int purchaseAmount,
      int tipAmount, int cashoutAmount, bool promptForCashout);

  Future<void> initiateRefundTx(String posRefId, int refundAmount);

  Future<void> acceptSignature(bool accepted);

  Future<void> submitAuthCode(String authCode);

  Future<void> cancelTransaction();

  Future<void> initiateCashoutOnlyTx(String posRefId, int amountCents);

  Future<void> initiateMotoPurchaseTx(String posRefId, int amountCents);

  Future<void> initiateSettleTx(String id);

  Future<void> initiateSettlementEnquiry(String posRefId);

  Future<void> initiateGetLastTx();

  Future<void> dispose();

  Future<void> setPromptForCustomerCopyOnEftpos(
      bool promptForCustomerCopyOnEftpos);

  Future<void> setSignatureFlowOnEftpos(bool signatureFlowOnEftpos);

  Future<void> setPrintMerchantCopy(bool printMerchantCopy);
}
