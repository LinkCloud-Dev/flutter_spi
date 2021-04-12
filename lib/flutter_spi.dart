import 'dart:async';

import 'package:flutter/services.dart';

class FlutterSpi {
  static const MethodChannel _channel = const MethodChannel('flutter_spi');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> get getVersion async {
    final String spiVersion = await _channel.invokeMethod('getVersion');
    return spiVersion;
  }

  static Future<void> get start async {
    await _channel.invokeMethod('start');
  }

  static Future<void> setPosId(String posId) async {
    await _channel.invokeMethod('setPosId', {"posId": posId});
  }
}
