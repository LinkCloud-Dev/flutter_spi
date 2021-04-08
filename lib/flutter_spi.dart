import 'dart:async';

import 'package:flutter/services.dart';

class FlutterSpi {
  static const MethodChannel _channel = const MethodChannel('flutter_spi');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> get sn async {
    final String serialNumber = await _channel.invokeMethod('getDeviceSN');
    return serialNumber;
  }
}
