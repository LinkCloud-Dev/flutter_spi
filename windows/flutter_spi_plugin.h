#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#pragma once

#ifndef FLUTTER_PLUGIN_FLUTTER_SPI_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_SPI_PLUGIN_H_

// This must be included before many other Windows headers.
// #include <iphlpapi.h>
#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>

#pragma comment(lib, "ws2_32")

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

// #include <memory>
#include <future>
#include <iostream>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#define LINKLY_HOST "127.0.0.1"
#define LINKLY_PORT "2011"
#define DEFAULT_BUFLEN 1024
#define START_FLAG '#'
#define PRINTER '0'

namespace flutter_spi {

class FlutterSpiPlugin : public flutter::Plugin {
   public:
    static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel;
    //  static std::thread thread;
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    FlutterSpiPlugin();

    virtual ~FlutterSpiPlugin();

    // Disallow copy and assign.
    FlutterSpiPlugin(const FlutterSpiPlugin &) = delete;
    FlutterSpiPlugin &operator=(const FlutterSpiPlugin &) = delete;

   private:
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

class Linkly {
   public:
    // static Linkly& get_instance();

    // Linkly(Linkly const &) = delete;
    // void operator=(Linkly const &) = delete;

    static std::string transaction_type;

    // Initialise Winsock and set socket information
    static int init();

    // Dummy function, does nothing
    static int start();

    // Connect socket to Linkly Client and log on to EFTPOS PIN pad
    static int pair();

    // Start purchasing process
    static int init_purchase(std::string reference, int purchase_amount, int cashout_amount);
   
    // Start settlement process
    static int init_settle(std::string reference);

    // Start refund process
    static int init_refund(std::string reference, int refund_amount);

    // Cancel transaction
    static int cancel_transaction();

    // Close socket connection
    static void close_connection();

    // Helper function to check if Winsock is initialised
    static bool WinsockInitialized();

    // Helper function to set the length bytes of the message
    static void update_message_length(std::vector<char> &message);

    // Accept signature or not
    static int accept_signature(bool accepted);

    // Get last transaction record
    static std::string get_last_transac();

    // Map paring flow state to EncodableValeu<std::map>
    static flutter::EncodableValue mapPairingFlowState(std::string message, bool finished);

    // Map transaction flow state to EncodableValue<std::map>
    static flutter::EncodableValue mapTransactionState(std::string reference, std::string type, bool finished,
                                                       std::string success, std::string message,
                                                       std::string receipt = "", std::string display_message = "",
                                                       bool attempt_to_cancel = false,
                                                       bool awaitingSignatureCheck = false,
                                                       std::string signature_message = "");

    // Map spi message to EncodableValue<std::map>
    static flutter::EncodableValue mapMessage(std::string message, std::string receipt,
                                              bool is_refund_or_settle = false, bool is_customer_receipt = false);

    // Helper function for flutter callbacks
    static void Linkly::pair_flow_changed(bool finished, std::string flow_text, std::string status_text);

    // Helper function for flutter callbacks
    static void Linkly::transac_flow_changed(bool finished, std::string flow_text, std::string is_success,
                                             std::string receipt = "", bool cancel = false, bool sign_check = false,
                                             std::string sign_msg = "");

   private:
    Linkly();

    static WSADATA wsa;
    static SOCKET s;
    static struct sockaddr_in server;

    static int iResult;
    static struct addrinfo *addr_result, *ptr, hints;

    // Following three variables are kept as states for cancelling transaction
    static bool allow_cancel;
    static std::string curr_ref;
};

}  // namespace flutter_spi

// Helper function to get value from EncodableMap
const flutter::EncodableValue *ValueOrNull(const flutter::EncodableMap &map, const char *key);

#endif  // FLUTTER_PLUGIN_FLUTTER_SPI_PLUGIN_H_
