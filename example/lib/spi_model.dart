import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpiModel extends ChangeNotifier {
  SpiStatus status;
  String posId;
  String eftPosId;
  String eftPosAddress;
  bool testMode;
  bool autoAddress;
  Secrets secrets;
  PairingFlowState pairingFlowState;
  TransactionFlowState transactionFlowState;

  SpiModel({
    this.status = SpiStatus.UNPAIRED,
    this.posId,
    this.eftPosId,
    this.eftPosAddress,
    this.testMode = false,
    this.autoAddress = false,
    this.secrets,
  });

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    posId = prefs.getString('posId');
    eftPosId = prefs.getString('eftPosId');
    eftPosAddress = prefs.getString('eftPosAddress');
    final persistedSecrets = prefs.getString('secrets');
    if (persistedSecrets != null) {
      secrets = Secrets.fromMap(jsonDecode(persistedSecrets));
    }

    // start spi
    if (posId != null &&
        eftPosId != null &&
        eftPosAddress != null &&
        secrets != null) {
      await FlutterSpi.init(posId, eftPosId, eftPosAddress,
          secrets: secrets.toJSON());
    }
  }

  void updatePosId(String value) {
    posId = value;
  }

  void updateEftPosId(String value) {
    eftPosId = value;
  }

  void updateEftPosAddress(String value) {
    eftPosAddress = value;
  }

  void updateTestMode(bool value) {
    testMode = value;
  }

  void updateAutoAddress(bool value) {
    autoAddress = value;
  }

  Future<void> subscribeSpiEvents(MethodCall methodCall) async {
    SpiMethodCallEvents eventType =
        EnumToString.fromString(SpiMethodCallEvents.values, methodCall.method);
    switch (eventType) {
      case SpiMethodCallEvents.statusChanged:
        status =
            EnumToString.fromString(SpiStatus.values, methodCall.arguments);
        notifyListeners();
        break;
      case SpiMethodCallEvents.pairingFlowStateChanged:
        pairingFlowState = PairingFlowState.fromMap(methodCall.arguments);
        notifyListeners();
        if (pairingFlowState.finished) {
          await FlutterSpi.ackFlowEndedAndBackToIdle();
        }
        break;
      case SpiMethodCallEvents.secretsChanged:
        secrets = Secrets.fromMap(methodCall.arguments);
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('secrets', jsonEncode(secrets.toJSON()));
        break;
      case SpiMethodCallEvents.txFlowStateChanged:
        transactionFlowState =
            TransactionFlowState.fromMap(methodCall.arguments);
        notifyListeners();
        if (transactionFlowState.awaitingSignatureCheck) {
          // TODO: print receipt to sign on paper & update UI for customer signature
          print(transactionFlowState.signatureRequiredMessage.receiptToSign);
          break;
        }
        if (transactionFlowState.finished) {
          await FlutterSpi.ackFlowEndedAndBackToIdle();
        }
        // TODO: should print merchant copy
        if (transactionFlowState.success == 'SUCCESS') {
          // TODO handle transaction success.
          print('Transaction Success.');
        }
        break;
      case SpiMethodCallEvents.deviceAddressChanged:
        // TODO:  handle device address changed
        break;
      default:
    }
  }

  Future<void> save() async {
    await FlutterSpi.setTestMode(testMode);
    await FlutterSpi.setAutoAddressResolution(autoAddress);
    if (posId.isNotEmpty) await FlutterSpi.setPosId(posId);
    if (eftPosId.isNotEmpty) await FlutterSpi.setSerialNumber(eftPosId);
    if (eftPosAddress.isNotEmpty)
      await FlutterSpi.setEftposAddress(eftPosAddress);
  }

  Future<void> pair() async {
    await save();
    // await FlutterSpi.init(posId, eftPosId, eftPosAddress);
    await FlutterSpi.pair();
  }

  Future<void> unpair() async {
    await FlutterSpi.unpair();
    secrets = null;
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
    prefs.setString('posId', posId);
    prefs.setString('eftPosId', eftPosId);
    prefs.setString('eftPosAddress', eftPosAddress);
    prefs.setString('secrets', jsonEncode(secrets.toJSON()));
  }

  Future<void> initiatePurchaseTx(String transactionId, int purchaseAmount,
      int tipAmount, int cashoutAmount, bool promptForCashout) async {
    await FlutterSpi.initiatePurchaseTx(transactionId, purchaseAmount,
        tipAmount, cashoutAmount, promptForCashout);
  }

  void resetTransaction() {
    transactionFlowState = null;
  }

  Future<void> retryTransaction(String transactionId, int purchaseAmount,
      int tipAmount, int cashoutAmount, bool promptForCashout) async {
    transactionFlowState = null;
    await FlutterSpi.initiatePurchaseTx(transactionId, purchaseAmount,
        tipAmount, cashoutAmount, promptForCashout);
  }
}
