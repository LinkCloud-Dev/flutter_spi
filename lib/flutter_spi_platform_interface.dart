import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_spi_method_channel.dart';

abstract class FlutterSpiPlatform extends PlatformInterface {
  /// Constructs a FlutterSpiPlatform.
  FlutterSpiPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSpiPlatform _instance = MethodChannelFlutterSpi();

  /// The default instance of [FlutterSpiPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSpi].
  static FlutterSpiPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSpiPlatform] when
  /// they register themselves.
  static set instance(FlutterSpiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
