#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#pragma once


#ifndef FLUTTER_PLUGIN_FLUTTER_SPI_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_SPI_PLUGIN_H_

// This must be included before many other Windows headers.
#include <winsock2.h>
#include <windows.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>

#pragma comment(lib, "ws2_32")

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

// #include <memory>
#include <sstream>

#include <iostream>
#include <vector>
#include <string>

namespace flutter_spi {

class FlutterSpiPlugin : public flutter::Plugin {
   public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    FlutterSpiPlugin();

    virtual ~FlutterSpiPlugin();

    // Disallow copy and assign.
    FlutterSpiPlugin(const FlutterSpiPlugin &) = delete;
    FlutterSpiPlugin &operator=(const FlutterSpiPlugin &) = delete;

   private:
    WSADATA wsa;
    SOCKET s = INVALID_SOCKET;
    struct sockaddr_in server;

    int iResult;
    struct addrinfo *addr_result = NULL, *ptr = NULL, hints;
    
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    // Initialise Winsock and set socket information
    int init();

    // Connect socket to Linkly Client
    int start();

    // Helper function to check if Winsock is initialised
    bool WinsockInitialized();
};

}  // namespace flutter_spi

#endif  // FLUTTER_PLUGIN_FLUTTER_SPI_PLUGIN_H_
