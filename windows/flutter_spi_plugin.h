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
    static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel;

    static WSADATA wsa;
    static SOCKET s;
    static struct sockaddr_in server;

    static int iResult;
    static struct addrinfo *addr_result, *ptr, hints;
    
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    // Initialise Winsock and set socket information
    static int init();

    // Connect socket to Linkly Client
    static int start();

    // Log on to EFTPOS PIN pad
    static int pair();

    // Close socket connection
    static void close_connection();
    
    // Helper function to check if Winsock is initialised
    static bool WinsockInitialized();

    // Helper function to set the length bytes of the message
    static void update_message_length(std::vector<char>& message);

};

}  // namespace flutter_spi

#endif  // FLUTTER_PLUGIN_FLUTTER_SPI_PLUGIN_H_
