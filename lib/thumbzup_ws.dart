import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi/flutter_spi_platform.dart';
import 'package:flutter_spi/thumbzup_status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ThumbzUpWebSocket implements FlutterSpiPlatform {
  static const MethodChannel _channel = MethodChannel('flutter_spi');

  WebSocketChannel? _websocket;

  String _merchantId = "";
  String _username = "";
  String _applicationKey = "";
  String _serialNumber = "";
  String? _authenticationKey;

  Function _logCallback = (PbLogType logType, String msg) {
    // Default logger
    if (logType == PbLogType.info) {
      log(msg);
    } else if (logType == PbLogType.receiveData) {
      log("Received data: $msg");
    } else if (logType == PbLogType.transmitData) {
      log("Transmit data: $msg");
    } else {
      log("Websocket error: $msg", error: WebSocketException(msg));
    }
  };

  // Only here to retrofit other eftpos
  Function? _handleMethodCall;

  Function? _saleCallback;
  Function? _refundCallback;
  Function? _authCallback;
  Function? _pingCallback;
  Function? _printCallback;
  Function? _barcodeCallback;

  void _statusCallback(PbStatus status) {
    switch (status) {
      case PbStatus.connected:
        _handleMethodCall!(constructMethodCall(
            SpiMethodCallEvents.statusChanged,
            EnumToString.convertToString(SpiStatus.PAIRED_CONNECTED)));
        break;
      case PbStatus.disconnected:
        _handleMethodCall!(constructMethodCall(
            SpiMethodCallEvents.statusChanged,
            EnumToString.convertToString(SpiStatus.UNPAIRED)));
        break;
      case PbStatus.error:
        // TODO: to be confirmed whether ws connection is down
        _handleMethodCall!(constructMethodCall(
            SpiMethodCallEvents.statusChanged,
            EnumToString.convertToString(SpiStatus.UNPAIRED)));
        break;
    }
  }

  void _paringCallback(bool finished, bool successful, {String msg = ""}) {
    Map<String, dynamic> payload = {
      "message": msg,
      "awaitingCheckFromEftpos": false,
      "awaitingCheckFromPos": false,
      "finished": finished,
      "successful": successful,
    };
    _handleMethodCall!(constructMethodCall(
        SpiMethodCallEvents.pairingFlowStateChanged, payload));
  }

  void setMerchantId(String merchantId) {
    _merchantId = merchantId;
  }

  void setUsername(String username) {
    _username = username;
  }

  void setApplicationKey(String applicationKey) {
    _applicationKey = applicationKey;
  }

  void setLogCallback(Function callback) {
    _logCallback = callback;
  }

  void setAuthenticationKey(String key) {
    _authenticationKey = key;
  }

  Future<void> connect(String deviceIdentifier) async {
    await disconnect();
    deviceIdentifier = deviceIdentifier.replaceAll(RegExp(r"/\s/g"), "");
    _logCallback(PbLogType.info, "Connecting to $deviceIdentifier...");

    _paringCallback(false, false, msg: "Connecting to $deviceIdentifier...");

    _websocket = WebSocketChannel.connect(
        Uri.parse("wss://$deviceIdentifier.thumbzup.mobi:8080"));

    _websocket!.stream.listen((event) {
      log(event);
      final eventJson = json.decode(event);
      // TODO: to be confirmed if key is correct
      switch (eventJson["type"]) {
        case "open":
          _logCallback(PbLogType.info, "Websocket CONNECTED");
          _statusCallback(PbStatus.connected);
          _paringCallback(true, true,
              msg: "Websocket CONNECTED");
          break;
        case "close":
          _logCallback(PbLogType.info, "Websocket DISCONNECTED");
          _statusCallback(PbStatus.disconnected);
          break;
        case "message":
          // TODO: to be confirmed if key is correct
          _logCallback(PbLogType.receiveData, eventJson["data"]);
          final data = eventJson["data"];

          // Posbuddy response
          if (data["commandPayload"] != null &&
              data["commandId"] == "PAY_APP_RESPONSE") {
            final commandPayload = data["commandPayload"];
            if (commandPayload["launchType"] == "SALE") {
              _saleCallback!(commandPayload);
            } else if (commandPayload["launchType"] == "REFUND") {
              _refundCallback!(commandPayload);
            } else if (commandPayload["launchType"] == "AUTH" ||
                commandPayload["launchType"] == "RETAIL_AUTH") {
              _authCallback!(commandPayload);
            }
          } else if (data["commandId"] == "PING_RESPONSE" &&
              data["result"] != null) {
            _pingCallback!(
                {"result": data["result"], "payload": data["commandPayload"]});
          } else if (data["commandId"] == "PRINT_SUNMI_COMMANDS_RESPONSE" &&
              data["result"] != null) {
            _printCallback!({"result": data["result"]});
          } else if (data["commandId"] == "BARCODE_VALUE" &&
              data["commandPayload"] != null) {
            _barcodeCallback!(data["commandPayload"]["value"]);
          }
      }
    }, onError: (event) {
      _logCallback(PbLogType.error, "Websocket error: ${event.toString()}");
      _statusCallback(PbStatus.error);
      _paringCallback(true, false,
              msg: "Unable to connect");
    });

    // Wait for ws to connect
    await _websocket!.ready;
  }

  Future<void> disconnect() async {
    if (_websocket != null) {
      await _websocket!.sink.close(status.normalClosure);
    }
  }

  Future<void> sendMessage(dynamic obj) async {
    final msg = json.encode(obj);

    _logCallback(PbLogType.transmitData, msg);
    _websocket!.sink.add(msg);
  }

  Future<void> doAuth(Function callback) async {
    if (_websocket == null) {
      callback({
        "errorBundle": {
          "description": "Error",
          "message": "Websocket not connected"
        }
      });
      return;
    }

    _authCallback = callback;

    sendMessage({
      "commandId": "PAY_APP_RQST",
      "commandPayload": {
        "launchType": "AUTH",
        "applicationKey": _applicationKey,
        "merchantID": _merchantId,
        "merchantUsername": _username,
      },
    });
  }

  MethodCall constructMethodCall(Enum callType, dynamic arguments) {
    return MethodCall(EnumToString.convertToString(callType), arguments);
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
  Future<String> get getDeviceSN async {
    final String sn = await _channel.invokeMethod('getDeviceSN');
    return sn;
  }

  @override
  void handleMethodCall(callback) {
    _handleMethodCall = callback;
  }

  // "appKey" compulsory
  // "merchantId" compulsory
  // "username" compulsory
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
    setApplicationKey(appKey!);
    setUsername(username);
    setMerchantId(merchantId!);
    setSerialNumber(serialNumber!);
  }

  @override
  Future<void> initiatePurchaseTx(String posRefId, int purchaseAmount,
      int tipAmount, int cashoutAmount, bool promptForCashout) {
    // TODO: implement initiatePurchaseTx
    throw UnimplementedError();
  }

  @override
  Future<void> initiateRefundTx(String posRefId, int refundAmount) {
    // TODO: implement initiateRefundTx
    throw UnimplementedError();
  }

  @override
  Future<void> pair() async {
    await connect(_serialNumber);
  }

  @override
  Future<void> unpair() async {
    await disconnect();
  }

  @override
  Future<void> pairingCancel() async {
    await disconnect();
  }

  @override
  Future<void> setSerialNumber(String serialNumber) async {
    _serialNumber = serialNumber;
  }

  /*======================================================
  
  
  
  
                                                         
    Methods below are not needed for ThumbzUp integration
  
  
  
  
  ======================================================*/

  @override
  Future<List<Tenant>> getTenantsList(String apiKey,
      {String countryCode = "AU"}) async {
    // NOT NEEDED
    return [];
  }

  @override
  Future<String> get getVersion async {
    // NOT NEEDED
    return "";
  }

  @override
  Future<void> initiateGetLastTx() async {
    // NOT NEEDED
  }

  @override
  Future<void> start() async {
    // NOT NEEDED
  }

  @override
  Future<void> initiateCashoutOnlyTx(String posRefId, int amountCents) async {
    // NOT NEEDED
  }

  @override
  Future<void> initiateMotoPurchaseTx(String posRefId, int amountCents) async {
    // NOT NEEDED
  }

  @override
  Future<void> initiateSettleTx(String id) async {
    // NOT NEEDED
  }

  @override
  Future<void> initiateSettlementEnquiry(String posRefId) async {
    // NOT NEEDED
  }

  @override
  Future<void> setPosId(String posId) async {
    // NOT NEEDED
  }

  @override
  Future<void> setPosInfo(String posVendorId, String posVersion) async {
    // NOT NEEDED
  }

  @override
  Future<void> setPrintMerchantCopy(bool printMerchantCopy) async {
    // NOT NEEDED
  }

  @override
  Future<void> setPromptForCustomerCopyOnEftpos(
      bool promptForCustomerCopyOnEftpos) async {
    // NOT NEEDED
  }

  @override
  Future<void> submitAuthCode(String authCode) async {
    // NOT NEEDED
  }

  @override
  Future<void> setSignatureFlowOnEftpos(bool signatureFlowOnEftpos) async {
    // NOT NEEDED
  }

  @override
  Future<void> setTenantCode(String tenantCode) async {
    // NOT NEEDED
  }

  @override
  Future<void> acceptSignature(bool accepted) async {
    // NOT NEEDED
  }

  @override
  Future<void> ackFlowEndedAndBackToIdle() async {
    // NOT NEEDED
  }

  @override
  Future<void> pairingConfirmCode() async {
    // NOT NEEDED
  }

  @override
  Future<void> setEftposAddress(String address) async {
    // NOT NEEDED
  }
}
