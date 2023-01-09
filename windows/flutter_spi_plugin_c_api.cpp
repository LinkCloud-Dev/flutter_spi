#include "include/flutter_spi/flutter_spi_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_spi_plugin.h"

void FlutterSpiPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_spi::FlutterSpiPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
