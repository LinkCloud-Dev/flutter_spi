import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_spi_platform_interface.dart';

/// An implementation of [FlutterSpiPlatform] that uses method channels.
class MethodChannelFlutterSpi extends FlutterSpiPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_spi');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
