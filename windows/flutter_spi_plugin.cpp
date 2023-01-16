#include "flutter_spi_plugin.h"

#define LINKLY_HOST "127.0.0.1"
#define LINKLY_PORT "2011"
#define DEFAULT_BUFLEN 1024
#define START_FLAG '#'

const flutter::EncodableValue* ValueOrNull(const flutter::EncodableMap& map, const char* key);

namespace flutter_spi {

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> FlutterSpiPlugin::channel;
WSADATA FlutterSpiPlugin::wsa;
SOCKET FlutterSpiPlugin::s;
struct sockaddr_in FlutterSpiPlugin::server;

int FlutterSpiPlugin::iResult;
struct addrinfo *FlutterSpiPlugin::addr_result, *FlutterSpiPlugin::ptr, FlutterSpiPlugin::hints;

// static
void FlutterSpiPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
    channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "flutter_spi",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<FlutterSpiPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result) {
            if (call.method_name() == "init") {
                // TODO
                int _return_val = init();
                if (_return_val == 0) {
                    result->Success("Socket initialised.");
                } else {
                    result->Error("INIT_ERROR", "Socket initialisation failed.");
                }

            } else if (call.method_name() == "start") {
                int _return_val = start();
                if (_return_val == 0) {
                    result->Success("Socket connected.");

                } else {
                    result->Error("START_ERROR", "Socket connection failed.");
                }
            } else if (call.method_name() == "setPosId") {
                // Do nothing since not needed for Linkly
                result->Success(NULL);
            } else if (call.method_name() == "setSerialNumber") {
                // Do nothing since not needed for Linkly
                result->Success(NULL);
            } else if (call.method_name() == "setEftposAddress") {
                // Do nothing since not needed for Linkly
                result->Success(NULL);
            } else if (call.method_name() == "setPosInfo") {
                // Do nothing since not needed for Linkly
                result->Success(NULL);

            } else if (call.method_name() == "ackFlowEndedAndBackToIdle") {
                // Do nothing since not needed for Linkly
                result->Success(NULL);
            } else if (call.method_name() == "pair") {
                // TODO
                int _return_val = pair();
                if (_return_val == 0) {
                    result->Success("Successfully logged on.");
                } else {
                    result->Error("PAIR_ERROR", "Unable to log on to EFTPOS PIN pad, or connect to Linkly client.");
                }
            } else if (call.method_name() == "pairingConfirmCode") {
                // NOT ACTUALLY USED FOR WINDWOS
                result->Success(NULL);
            } else if (call.method_name() == "pairingCancel") {
                // Linkly connection cannot be cancelled half way
                result->Success(NULL);
            } else if (call.method_name() == "unpair") {
                // TODO
                close_connection();
                result->Success("Successfully cancelled.");
            } else if (call.method_name() == "initiatePurchaseTx") {
                // TODO
                // int _return_val = init_purchase();
                int _return_val = 0;
                const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
                const auto* purchase_amt = std::get_if<int>(ValueOrNull(*arguments, "purchaseAmount"));
                std::cout << *purchase_amt << std::endl;
                if (_return_val == 0) {
                    result->Success("Purchase complete.");
                } else {
                    result->Error("PURCHASE_ERROR", "Unable to finish purchase transaction.");
                }

                // } else if (call.method_name() == "initiateRefundTx") {
                //     // TODO
                // } else if (call.method_name() == "acceptSignature") {
                //     // TODO
                // } else if (call.method_name() == "cancelTransaction") {
                //     // TODO
                // } else if (call.method_name() == "initiateSettleTx") {
                //     // TODO
                // } else if (call.method_name() == "initiateGetLastTx") {
                //     // TODO
                // } else if (call.method_name() == "initiateRecovery") {
                //     // TODO
                // } else if (call.method_name() == "setPromptForCustomerCopyOnEftpos") {
                //     // TODO
                // } else if (call.method_name() == "setSignatureFlowOnEftpos") {
                //     // TODO
                // } else if (call.method_name() == "setPrintMerchantCopy") {
                //     // TODO
            } else if (call.method_name() == "submitAuthCode") {
                // Send dummy code as Linkly does not use it
                result->Success(flutter::EncodableValue(12345));
            } else if (call.method_name() == "getDeviceSN") {
                // Send dummy code since Windows does not have consistent way to get a SN
                result->Success(flutter::EncodableValue("aaaa-bbbb-cccc"));
                // } else if (call.method_name() == "initiateMotoPurchaseTx") {
                //     // NOT USED
                // } else if (call.method_name() == "initiateCashoutOnlyTx") {
                //     // NOT USED
                // } else if (call.method_name() == "dispose") {
                //     // NOT USED
                // } else if (call.method_name() == "initiateSettlementEnquiry") {
                //     // NOT USED
                // } else if (call.method_name() == "getVersion") {
                //     // NOT USED
                // } else if (call.method_name() == "getCurrentStatus") {
                //     // NOT USED
                // } else if (call.method_name() == "getCurrentFlow") {
                //     // NOT USED
                // } else if (call.method_name() == "getCurrentPairingFlowState") {
                //     // NOT USED
                // } else if (call.method_name() == "getCurrentTxFlowState") {
                //     // NOT USED
                // } else if (call.method_name() == "getConfig") {
                //     // NOT USED
            } else {
                result->NotImplemented();
            }
        });
    registrar->AddPlugin(std::move(plugin));
}

FlutterSpiPlugin::FlutterSpiPlugin() {}

FlutterSpiPlugin::~FlutterSpiPlugin() {}

int FlutterSpiPlugin::init() {
    if (WinsockInitialized()) {
        printf("\nInitialising Winsock...\n");
        iResult = WSAStartup(MAKEWORD(2, 2), &wsa);
        if (iResult != 0) {
            printf("Failed. Error Code : %d", WSAGetLastError());
            return 1;
        }

        // Set socket information
        ZeroMemory(&hints, sizeof(hints));
        hints.ai_family = AF_INET;
        hints.ai_socktype = SOCK_STREAM;
        hints.ai_protocol = IPPROTO_TCP;

        iResult = getaddrinfo(LINKLY_HOST, LINKLY_PORT, &hints, &addr_result);
        if (iResult != 0) {
            printf("getaddrinfo failed: %d\n", iResult);
            WSACleanup();
            return 1;
        }
    }
    return 0;
}

int FlutterSpiPlugin::start() {
    return 0;
}

int FlutterSpiPlugin::pair() {
    ptr = addr_result;

    s = INVALID_SOCKET;
    s = socket(ptr->ai_family, ptr->ai_socktype, ptr->ai_protocol);

    if (s == INVALID_SOCKET) {
        printf("Error at socket(): %d\n", WSAGetLastError());
        freeaddrinfo(addr_result);
        WSACleanup();
        return 1;
    }

    // Connect to Linkly client
    iResult = connect(s, ptr->ai_addr, (int)ptr->ai_addrlen);
    if (iResult == SOCKET_ERROR) {
        closesocket(s);
        freeaddrinfo(addr_result);
        s = INVALID_SOCKET;
        return 1;
    }

    if (s == INVALID_SOCKET) {
        printf("Unable to connect to server!\n");
        freeaddrinfo(addr_result);
        WSACleanup();
        return 1;
    }

    std::cout << "Connected!" << std::endl;

    std::vector<char> message;
    char buffer[DEFAULT_BUFLEN];

    // Start flag
    message.push_back(START_FLAG);

    // Length
    message.insert(message.end(), 4, '0');

    // Command code
    message.push_back('G');

    // Sub code
    message.push_back(' ');

    // Merchant
    message.insert(message.end(), 2, '0');

    // Reciept auto-print
    message.push_back('9');

    // Cut receipt
    message.push_back('1');

    // app
    message.insert(message.end(), 2, '0');

    // Purchase analysis data
    message.insert(message.end(), 3, '0');

    update_message_length(message);

    iResult = send(s, message.data(), (int)message.size(), 0);
    if (iResult == SOCKET_ERROR) {
        printf("send failed: %d\n", iResult);
        close_connection();
        std::unique_ptr<flutter::EncodableValue> status = std::make_unique<flutter::EncodableValue>("UNPAIRED");
        channel->InvokeMethod("statusChanged", std::move(status));
        return 1;
    }

    do {
        iResult = recv(s, buffer, DEFAULT_BUFLEN, 0);
        if (iResult > 0) {
            // printf("Bytes received: %d\n", iResult);
            std::vector<char> buffer_vec(buffer, buffer + iResult);
            std::cout << buffer_vec.data() << std::endl;

            char start_flag = buffer_vec[0];
            if (start_flag != '#') {
                std::cout << "STRAT_FLAG does not match!" << std::endl;
                return 1;
            }

            // Check for event type
            // G: Log on event, read the response text and check if log on is successful
            // S: Display event, read the response text and pass it on to POS
            char command_code = buffer_vec[5];
            if (command_code == 'G') {
                char success_flag = buffer_vec[7];
                std::string res_text(buffer_vec.begin() + 10, buffer_vec.begin() + 30);
                res_text.erase(std::remove_if(res_text.begin(), res_text.end(), isspace), res_text.end());

                if (success_flag == '1') {

                    std::cout << "Log on successful!" << std::endl;

                    std::unique_ptr<flutter::EncodableValue> pair_flow_state = std::make_unique<flutter::EncodableValue>(mapPairingFlowState("Connected!", true));
                    channel->InvokeMethod("pairingFlowStateChanged", std::move(pair_flow_state));
                    std::unique_ptr<flutter::EncodableValue> status = std::make_unique<flutter::EncodableValue>("PAIRED_CONNECTED");
                    channel->InvokeMethod("statusChanged", std::move(status));
                    return 0;

                } else {

                    std::cout << "Log on failed!" << std::endl;

                    std::unique_ptr<flutter::EncodableValue> pair_flow_state = std::make_unique<flutter::EncodableValue>(mapPairingFlowState("ERROR: " + res_text, true));
                    channel->InvokeMethod("pairingFlowStateChanged", std::move(pair_flow_state));
                    std::unique_ptr<flutter::EncodableValue> status = std::make_unique<flutter::EncodableValue>("UNPAIRED");
                    channel->InvokeMethod("statusChanged", std::move(status));
                    return 1;

                }
            } else if (command_code == 'S') {
                std::cout << "Connecting" << std::endl;

                // std::string res_text(buffer_vec.begin() + 11, buffer_vec.begin() + 50);
                // res_text.erase(std::remove_if(res_text.begin(), res_text.end(), isspace), res_text.end());

                std::unique_ptr<flutter::EncodableValue> pair_flow_state = std::make_unique<flutter::EncodableValue>(mapPairingFlowState("Connecting...", false));
                channel->InvokeMethod("pairingFlowStateChanged", std::move(pair_flow_state));
                std::unique_ptr<flutter::EncodableValue> status = std::make_unique<flutter::EncodableValue>("PAIRED_CONNECTING");
                channel->InvokeMethod("statusChanged", std::move(status));
            }
        } else if (iResult == 0) {
            printf("Connection closed\n");
            close_connection();
            return 1;
        } else {
            printf("recv failed: %d\n", WSAGetLastError());
            close_connection();
            return 1;
        }
    } while (true);

    return 0;
}

int FlutterSpiPlugin::init_purchase(std::string reference, int purchase_amount, int tip_amount, int cashout_amount) {
    std::vector<char> message;
    char buffer[DEFAULT_BUFLEN];

    // Start flag
    message.push_back(START_FLAG);

    // Length
    message.insert(message.end(), 4, '0');

    // Command code
    message.push_back('M');

    // Sub code
    message.push_back('0');

    // Merchant
    message.insert(message.end(), 2, '0');

    // Transaction type
    message.push_back('P');

    // Training mode
    message.push_back('0');

    // Enable tip
    message.push_back('0');

    // Amount cash
    message.insert(message.end(), 9, '0');

    // Amount purchase
    message.insert(message.end(), 6, '0');
    message.push_back('1');
    message.insert(message.end(), 2, '0');

    // Auth code
    message.insert(message.end(), 6, ' ');

    // Transaction reference
    message.insert(message.end(), 16, 'a');

    // Reciept auto-print
    message.push_back('9');

    // Cut receipt
    message.push_back('1');

    // Pan source
    message.push_back(' ');

    // Pan
    message.insert(message.end(), 20, ' ');

    // expiry date
    message.insert(message.end(), 4, ' ');

    // track 2
    message.insert(message.end(), 40, ' ');

    // Account type
    message.push_back(' ');

    // app
    message.insert(message.end(), 2, '0');

    // RRN
    message.insert(message.end(), 12, 'b');

    // Currency code
    message.insert(message.end(), 3, ' ');

    // Original txn type
    message.push_back(' ');

    // Voucher date
    message.insert(message.end(), 6, ' ');

    // Voucher time
    message.insert(message.end(), 6, ' ');

    // Reserved
    message.insert(message.end(), 8, ' ');

    // Purchase analysis data len
    message.insert(message.end(), 3, '0');

    update_message_length(message);

    iResult = send(s, message.data(), (int)message.size(), 0);
    if (iResult == SOCKET_ERROR) {
        printf("send failed: %d\n", iResult);
        close_connection();
        std::unique_ptr<flutter::EncodableValue> status = std::make_unique<flutter::EncodableValue>("UNPAIRED");
        channel->InvokeMethod("statusChanged", std::move(status));
        return 1;
    }

    do {
        iResult = recv(s, buffer, DEFAULT_BUFLEN, 0);
        if (iResult > 0) {
            std::vector<char> buffer_vec(buffer, buffer + iResult);
            std::cout << buffer_vec.data() << std::endl;

            char start_flag = buffer_vec[0];
            if (start_flag != '#') {
                std::cout << "STRAT_FLAG does not match!" << std::endl;
                return 1;
            }

            // Check for event type
            // G: Log on event, read the response text and check if log on is successful
            // S: Display event, read the response text and pass it on to POS
            char command_code = buffer_vec[5];
            if (command_code == 'G') {
                char success_flag = buffer_vec[7];
                std::string res_text(buffer_vec.begin() + 10, buffer_vec.begin() + 30);
                res_text.erase(std::remove_if(res_text.begin(), res_text.end(), isspace), res_text.end());

                if (success_flag == '1') {

                    std::cout << "Log on successful!" << std::endl;

                    std::unique_ptr<flutter::EncodableValue> pair_flow_state = std::make_unique<flutter::EncodableValue>(mapPairingFlowState("Connected!", true));
                    channel->InvokeMethod("pairingFlowStateChanged", std::move(pair_flow_state));
                    std::unique_ptr<flutter::EncodableValue> status = std::make_unique<flutter::EncodableValue>("PAIRED_CONNECTED");
                    channel->InvokeMethod("statusChanged", std::move(status));
                    return 0;

                } else {

                    std::cout << "Log on failed!" << std::endl;

                    std::unique_ptr<flutter::EncodableValue> pair_flow_state = std::make_unique<flutter::EncodableValue>(mapPairingFlowState("ERROR: " + res_text, true));
                    channel->InvokeMethod("pairingFlowStateChanged", std::move(pair_flow_state));
                    std::unique_ptr<flutter::EncodableValue> status = std::make_unique<flutter::EncodableValue>("UNPAIRED");
                    channel->InvokeMethod("statusChanged", std::move(status));
                    return 1;

                }
            } else if (command_code == 'S') {
                std::cout << "Connecting" << std::endl;

                // std::string res_text(buffer_vec.begin() + 11, buffer_vec.begin() + 50);
                // res_text.erase(std::remove_if(res_text.begin(), res_text.end(), isspace), res_text.end());

                // std::unique_ptr<flutter::EncodableValue> pair_flow_state = std::make_unique<flutter::EncodableValue>(mapPairingFlowState("Connecting...", false));
                // channel->InvokeMethod("txFlowStateChanged", std::move(pair_flow_state));
            }
        } else if (iResult == 0) {
            printf("Connection closed\n");
            close_connection();
            return 1;
        } else {
            printf("recv failed: %d\n", WSAGetLastError());
            close_connection();
            return 1;
        }
    } while (true);

    return 0;
}

void FlutterSpiPlugin::close_connection() {
    std::unique_ptr<flutter::EncodableValue> status = std::make_unique<flutter::EncodableValue>("UNPAIRED");
    channel->InvokeMethod("statusChanged", std::move(status));
    freeaddrinfo(addr_result);
    closesocket(s);
    WSACleanup();
}

bool FlutterSpiPlugin::WinsockInitialized() {
    SOCKET test = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (test == INVALID_SOCKET) {
        return false;
    }
    closesocket(test);
    return true;
}

void FlutterSpiPlugin::update_message_length(std::vector<char> &message) {
    // Update the length of message
    std::string message_len = std::to_string((int)message.size());

    int temp_len_i = 4;
    for (auto it = message_len.rbegin(); it != message_len.rend(); ++it, --temp_len_i) {
        message[temp_len_i] = *it;
    }
}

flutter::EncodableValue FlutterSpiPlugin::mapPairingFlowState(std::string message, bool finished) {
    std::map<flutter::EncodableValue, flutter::EncodableValue> map;
    map[flutter::EncodableValue("message")] = flutter::EncodableValue(message);
    map[flutter::EncodableValue("awaitingCheckFromEftpos")] = flutter::EncodableValue(false);
    map[flutter::EncodableValue("awaitingCheckFromPos")] = flutter::EncodableValue(false);
    map[flutter::EncodableValue("confirmationCode")] = flutter::EncodableValue("");
    map[flutter::EncodableValue("finished")] = flutter::EncodableValue(finished);
    map[flutter::EncodableValue("successful")] = flutter::EncodableValue(false);

    return flutter::EncodableValue(map);
}

}  // namespace flutter_spi

const flutter::EncodableValue* ValueOrNull(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return nullptr;
  }
  return &(it->second);
}
