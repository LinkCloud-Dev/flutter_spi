import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpiModel extends ChangeNotifier {
  SpiStatus status;
  String? posId;
  String? serialNumber;
  String? eftPosAddress;
  String? apiKey;
  String? tenantCode;
  Secrets? secrets;
  PairingFlowState? pairingFlowState;
  TransactionFlowState? transactionFlowState;

  SpiModel({
    this.status = SpiStatus.UNPAIRED,
    this.posId,
    this.serialNumber,
    this.eftPosAddress,
    this.apiKey,
    this.tenantCode,
    this.secrets,
  });

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    posId = prefs.getString('posId');
    if (posId == null) {
      posId = await FlutterSpi.getDeviceSN;
      posId = posId!.replaceAll('-', '');
      if (posId!.length > 16) posId = posId!.substring(1, 16);
    }
    serialNumber = prefs.getString('serialNumber') ?? '000-000-000';
    eftPosAddress = prefs.getString('eftPosAddress') ?? '192.168.1.99';
    apiKey = "BurgerPosDeviceAPIKey";
    tenantCode = "wbc";
    final persistedSecrets = prefs.getString('secrets');
    if (persistedSecrets != null) {
      secrets = Secrets.fromMap(jsonDecode(persistedSecrets));
    }
    notifyListeners();
    // start spi
    // Non thumbzup machine

    await FlutterSpi.init(
        posId: posId!,
        serialNumber: serialNumber!,
        eftposAddress: eftPosAddress!,
        apiKey: apiKey!,
        tenantCode: tenantCode!,
        spiType: "TIMAPI",
        secrets: secrets != null ? secrets!.toJSON() : null);

    // // TODO: Add keys
    // // Thumbzup machine
    // await FlutterSpi.init(
    //   appKey: "ca1f5a1b-e582-40f3-86e9-c24269783b6f",
    //   merchantId: "112223334",
    //   serialNumber: serialNumber,
    //   secrets: {
    //     "secretKey": "GSGjgneRLmDbf/9l*nDMh2nEa/1A*3297S9UX3Pk",
    //     "accessKey": "5T73RL8TJUCT4SCM98DU",
    //   },
    //   spiType: "THUMBZUP",
    //   username: "default",
    // );
    await FlutterSpi.start();
  }

  void updatePosId(String value) {
    posId = value;
    notifyListeners();
  }

  void updateSerialNumber(String value) {
    serialNumber = value;
    notifyListeners();
  }

  void updateEftPosAddress(String value) {
    eftPosAddress = value;
    notifyListeners();
  }

  Future<void> subscribeSpiEvents(MethodCall methodCall) async {
    try {
      SpiMethodCallEvents? eventType = EnumToString.fromString(
          SpiMethodCallEvents.values, methodCall.method);
      print(methodCall);
      switch (eventType) {
        case SpiMethodCallEvents.statusChanged:
          status =
              EnumToString.fromString(SpiStatus.values, methodCall.arguments)!;
          notifyListeners();
          break;
        case SpiMethodCallEvents.pairingFlowStateChanged:
          pairingFlowState = PairingFlowState.fromMap(methodCall.arguments);
          notifyListeners();
          if (pairingFlowState!.finished) {
            await FlutterSpi.ackFlowEndedAndBackToIdle();
          }
          break;
        case SpiMethodCallEvents.secretsChanged:
          secrets = Secrets.fromMap(methodCall.arguments);
          notifyListeners();
          final prefs = await SharedPreferences.getInstance();
          if (secrets == null) {
            prefs.remove('secrets');
          } else {
            prefs.setString('secrets', jsonEncode(secrets!.toJSON()));
          }
          break;
        case SpiMethodCallEvents.txFlowStateChanged:
          transactionFlowState =
              TransactionFlowState.fromMap(methodCall.arguments);
          notifyListeners();
          if (transactionFlowState!.awaitingSignatureCheck) {
            // TODO: print receipt to sign on paper & update UI for customer signature
            print(
                transactionFlowState!.signatureRequiredMessage!.receiptToSign);
            break;
          }
          if (transactionFlowState!.finished) {
            await FlutterSpi.ackFlowEndedAndBackToIdle();
          }
          // TODO: should print merchant copy
          if (transactionFlowState!.success == 'SUCCESS') {
            // TODO handle transaction success.
            print('Transaction Success.');
          }
          break;
        default:
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> save() async {
    // await FlutterSpi.setTestMode(testMode);
    // await FlutterSpi.setAutoAddressResolution(autoAddress);
    if (posId!.isNotEmpty) await FlutterSpi.setPosId(posId!);
    if (serialNumber!.isNotEmpty) {
      await FlutterSpi.setSerialNumber(serialNumber!);
    }
    if (eftPosAddress!.isNotEmpty) {
      await FlutterSpi.setEftposAddress(eftPosAddress!);
    }
    print('Save Success.');
    print(posId);
    print(serialNumber);
    print(eftPosAddress);
  }

  Future<void> pair() async {
    await save();
    // await FlutterSpi.init(posId, eftPosId, eftPosAddress);
    await FlutterSpi.pair();
  }

  Future<void> unpair() async {
    await FlutterSpi.unpair();
    secrets = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('secrets');
  }

  Future<void> cancelPair() async {
    await FlutterSpi.pairingCancel();
  }

  Future<void> confirmPairingCode() async {
    await FlutterSpi.pairingConfirmCode();
  }

  Future<void> persistentStoreData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('posId', posId!);
    prefs.setString('eftPosAddress', eftPosAddress!);
    prefs.setString('secrets', jsonEncode(secrets!.toJSON()));
  }

  Future<void> initiatePurchaseTx(String transactionId, int purchaseAmount,
      int tipAmount, int cashoutAmount, bool promptForCashout) async {
    resetTransaction();
    await FlutterSpi.initiatePurchaseTx(transactionId, purchaseAmount,
        tipAmount, cashoutAmount, promptForCashout);
  }

  void resetTransaction() {
    transactionFlowState = null;
    notifyListeners();
  }

  Future<void> retryTransaction(String transactionId, int purchaseAmount,
      int tipAmount, int cashoutAmount, bool promptForCashout) async {
    transactionFlowState = null;
    await FlutterSpi.initiatePurchaseTx(transactionId, purchaseAmount,
        tipAmount, cashoutAmount, promptForCashout);
  }

  Future<void> retryRefundTransaction(
    String transactionId,
    int refundAmount,
  ) async {
    transactionFlowState = null;
    await FlutterSpi.initiateRefundTx(transactionId, refundAmount);
  }
}
