#ifndef FLUTTER_PLUGIN_FLUTTER_SPI_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_SPI_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_spi {

class FlutterSpiPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterSpiPlugin();

  virtual ~FlutterSpiPlugin();

  // Disallow copy and assign.
  FlutterSpiPlugin(const FlutterSpiPlugin&) = delete;
  FlutterSpiPlugin& operator=(const FlutterSpiPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_spi

#endif  // FLUTTER_PLUGIN_FLUTTER_SPI_PLUGIN_H_
