import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter_spi/flutter_spi.dart';

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
        // TODO: should persist spi pair info
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
    await FlutterSpi.pair();
  }

  Future<void> unpair() async {
    await FlutterSpi.unpair();
  }
}
