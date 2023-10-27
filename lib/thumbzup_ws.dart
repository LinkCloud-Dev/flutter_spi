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

  String? currentTxId;
  int? currentTxAmount;

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

  Function? _printCallback;
  Function? _barcodeCallback;

  void _authCallback(Map<String, dynamic> data) {
    if (data["errorBundle"] != null) {
      _handleMethodCall!(
        constructMethodCall(
          SpiMethodCallEvents.txFlowStateChanged,
          {
            "posRefId": currentTxId,
            "type": "PURCHASE",
            "amountCents": currentTxAmount,
            "finished": true,
            "success": "FAILED",
            "response": {
              "data": {
                "host_response_text":
                    "${data["errorBundle"]["description"]}\n ${data["errorBundle"]["message"]}",
              }
            },
          },
        ),
      );
      return;
    }

    setAuthenticationKey(data["authenticationKey"]);
  }

  void _pingCallback(Map<String, dynamic> data) {
    if (data["errorBundle"] != null) {
      // log("Ping error: ${data["errorBundle"]["description"]}\n ${data["errorBundle"]["message"]}");
      _statusCallback(PbStatus.disconnected);
      _paringCallback(
        true,
        false,
        msg:
            "Ping error: ${data["errorBundle"]["description"]}\n ${data["errorBundle"]["message"]}",
      );
    } else if (data["result"] != "SUCCESS") {
      _statusCallback(PbStatus.disconnected);
      _paringCallback(true, false, msg: "Websocket not connected");
    } else {
      _statusCallback(PbStatus.connected);
      _paringCallback(true, true, msg: "Websocket CONNECTED");
    }
  }

  void _statusCallback(PbStatus status) {
    switch (status) {
      case PbStatus.connected:
        _handleMethodCall!(constructMethodCall(
          SpiMethodCallEvents.statusChanged,
          EnumToString.convertToString(SpiStatus.PAIRED_CONNECTED),
        ));
        break;
      case PbStatus.disconnected:
        _handleMethodCall!(constructMethodCall(
          SpiMethodCallEvents.statusChanged,
          EnumToString.convertToString(SpiStatus.UNPAIRED),
        ));
        break;
      case PbStatus.error:
        // TODO: to be confirmed whether ws connection is down
        _handleMethodCall!(constructMethodCall(
          SpiMethodCallEvents.statusChanged,
          EnumToString.convertToString(SpiStatus.UNPAIRED),
        ));
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

  void _transactionCallback(Map<String, dynamic> data, String type) {
    if (data["errorBundle"] != null) {
      _handleMethodCall!(
        constructMethodCall(
          SpiMethodCallEvents.txFlowStateChanged,
          {
            "posRefId": currentTxId,
            "type": type,
            "amountCents": currentTxAmount,
            "finished": true,
            "success": "FAILED",
            "response": {
              "data": {
                "host_response_text":
                    "${data["errorBundle"]["description"]}\n ${data["errorBundle"]["message"]}",
              }
            },
          },
        ),
      );
    } else {
      if (data["isApproved"] == "true") {
        // Sale is approved
        _handleMethodCall!(
          constructMethodCall(
            SpiMethodCallEvents.txFlowStateChanged,
            {
              "posRefId": data["transactionUuid"],
              "type": type,
              "amountCents": int.parse(data["transactionAmount"]),
              "finished": true,
              "success": "SUCCESS",
              "response": {
                "data": {
                  "host_response_text": "Transaction successful",
                }
              },
            },
          ),
        );
      } else if (data["isApproved"] == "false") {
        // Sale is declined due to PIN mismatch
        _handleMethodCall!(
          constructMethodCall(
            SpiMethodCallEvents.txFlowStateChanged,
            {
              "posRefId": data["transactionUuid"],
              "type": type,
              "amountCents": int.parse(data["transactionAmount"]),
              "finished": true,
              "success": "FAILED",
              "displayMessage": "Transaction declined, invalid PIN",
            },
          ),
        );
      } else {
        // Sale is declined by the bank or unknown error
        _handleMethodCall!(
          constructMethodCall(
            SpiMethodCallEvents.txFlowStateChanged,
            {
              "posRefId": data["transactionUuid"],
              "type": type,
              "amountCents": int.parse(data["transactionAmount"]),
              "finished": true,
              "success": "FAILED",
              "displayMessage": "Transaction declined, check with your bank",
            },
          ),
        );
      }
    }
    currentTxAmount = null;
    currentTxId = null;
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
          break;
        case "close":
          _logCallback(PbLogType.info, "Websocket DISCONNECTED");
          _statusCallback(PbStatus.disconnected);
          _paringCallback(true, false, msg: "Websocket DISCONNECTED");
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
              _transactionCallback(commandPayload, "PURCHASE");
            } else if (commandPayload["launchType"] == "REFUND") {
              _transactionCallback(commandPayload, "REFUND");
            } else if (commandPayload["launchType"] == "AUTH" ||
                commandPayload["launchType"] == "RETAIL_AUTH") {
              _authCallback(commandPayload);
            }
          } else if (data["commandId"] == "PING_RESPONSE" &&
              data["result"] != null) {
            _pingCallback(
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
      _paringCallback(true, false, msg: "Unable to connect");
    });

    // Wait for ws to connect
    // await _websocket!.ready;

    // Check connection
    pingDevice();
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

  void pingDevice() {
    if (_websocket == null) {
      _pingCallback({
        "errorBundle": {
          "description": "Error",
          "message": "Websocket not Connected"
        }
      });
      return;
    }

    sendMessage({"commandId": "PING"});
  }

  void clearItems() {
    var obj = {"commandId": "CLEAR_DISPLAY"};

    sendMessage(obj);
  }

  void displayItems(int totalCost, {dynamic items}) {
    var itemList = [];

    if (items != null) {
      items.map((element) {
        itemList.add({
          "quantity": element["count"],
          "cost": formatCurrency(element["count"] * element["price"]),
          "description": element["description"],
        });
      });
    }

    var obj = {
      "commandId": "ITEM_DISPLAY",
      "commandPayload": {"items": itemList, "total": formatCurrency(totalCost)}
    };

    sendMessage(obj);
  }

  Future<void> doAuth() async {
    if (_websocket == null) {
      _authCallback({
        "errorBundle": {
          "description": "Error",
          "message": "Websocket not connected"
        }
      });
      return;
    }

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

  Future<void> doSale(int amount, {Map<String, dynamic>? extraParams}) async {
    if (_websocket == null) {
      _transactionCallback({
        "errorBundle": {
          "description": "Error",
          "message": "Websocket not Connected"
        }
      }, "PURCHASE");
      return;
    }

    Map<String, dynamic> obj = {
      "commandId": "PAY_APP_RQST",
      "commandPayload": {
        "launchType": "SALE",
        "applicationKey": _applicationKey,
        "merchantID": _merchantId,
        "merchantUsername": _username,
        "transactionAmount": amount,
      }
    };

    if (extraParams != null) {
      obj.addAll(extraParams);
    }

    sendMessage(obj);

    _handleMethodCall!(
      constructMethodCall(
        SpiMethodCallEvents.txFlowStateChanged,
        {
          "posRefId": currentTxId,
          "type": "PURCHASE",
          "amountCents": amount,
          "finished": false,
        },
      ),
    );
  }

  Future<void> doRefund(String uuid, int amount,
      {Map<String, dynamic>? extraParams}) async {
    if (_websocket == null) {
      _transactionCallback({
        "errorBundle": {
          "description": "Error",
          "message": "Websocket not Connected"
        }
      }, "REFUND");
      return;
    }

    Map<String, dynamic> obj = {
      "commandId": "PAY_APP_RQST",
      "commandPayload": {
        "launchType": "REFUND",
        "applicationKey": _applicationKey,
        "merchantID": _merchantId,
        "merchantUsername": _username,
        "originalTransactionUuid": uuid,
        "transactionAmount": amount,
      }
    };

    if (extraParams != null) {
      obj.addAll(extraParams);
    }

    sendMessage(obj);

    _handleMethodCall!(
      constructMethodCall(
        SpiMethodCallEvents.txFlowStateChanged,
        {
          "posRefId": currentTxId,
          "type": "REFUND",
          "amountCents": amount,
          "finished": false,
        },
      ),
    );
  }

  String formatCurrency(int cents) {
    return "AU\$ ${(cents / 100).toStringAsFixed(2).replaceAll(RegExp(r"/\B(?=(\d{3})+(?!\d))/g"), " ")}";
  }

  MethodCall constructMethodCall(Enum callType, dynamic arguments) {
    return MethodCall(EnumToString.convertToString(callType), arguments);
  }

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
      int tipAmount, int cashoutAmount, bool promptForCashout) async {
    await doAuth();
    currentTxAmount = purchaseAmount + tipAmount;
    currentTxId = posRefId;
    Map<String, dynamic> payload = {
      "transactionReferenceNo": currentTxId,
    };

    await doSale(currentTxAmount!, extraParams: payload);
  }

  @override
  Future<void> initiateRefundTx(String posRefId, int refundAmount) async {
    await doAuth();
    currentTxAmount = refundAmount;
    currentTxId = posRefId;
    Map<String, dynamic> payload = {
      "transactionReferenceNo": currentTxId,
    };
    await doRefund(posRefId, refundAmount, extraParams: payload);
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
  Future<void> dispose() async {
    // NOT NEEDED
  }

  @override
  Future<Map<String, bool>> get getConfig async {
    // NOT NEEDED
    return {};
  }

  @override
  Future<String> get getCurrentFlow async {
    // NOT NEEDED
    return "";
  }

  @override
  Future<String> get getCurrentPairingFlowState async {
    // NOT NEEDED
    return "";
  }

  @override
  Future<String> get getCurrentStatus async {
    // NOT NEEDED
    return "";
  }

  @override
  Future<String> get getCurrentTxFlowState async {
    // NOT NEEDED
    return "";
  }

  @override
  Future<void> cancelTransaction() async {
    // Not supported
  }

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
