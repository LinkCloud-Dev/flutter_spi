#include "flutter_spi_plugin.h"

#define LINKLY_HOST "127.0.0.1"
#define LINKLY_PORT "2011"
#define DEFAULT_BUFLEN 1024
#define START_FLAG '#'

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
        if (_return_val == 0){
            result->Success("Socket initialised.");
        }else{
            result->Error("INIT_ERROR", "Socket initialisation failed.");
        }

    } else if (call.method_name() == "start") {
        // TODO
        int _return_val = start();
        if (_return_val == 0){
            result->Success("Socket connected.");
            
        }else{
            result->Error("START_ERROR", "Socket connection failed.");
        }
    } else if (call.method_name() == "setPosId") {
        // TODO
        result->Success(NULL);
    } else if (call.method_name() == "setSerialNumber") {
        // TODO
        result->Success(NULL);
    } else if (call.method_name() == "setEftposAddress") {
        // TODO
        result->Success(NULL);
    } else if (call.method_name() == "setPosInfo") {
        // TODO
        result->Success(NULL);
    // } else if (call.method_name() == "getVersion") {
    //     // TODO
    // } else if (call.method_name() == "getCurrentStatus") {
    //     // TODO
    // } else if (call.method_name() == "getCurrentFlow") {
    //     // TODO
    // } else if (call.method_name() == "getCurrentPairingFlowState") {
    //     // TODO
    // } else if (call.method_name() == "getCurrentTxFlowState") {
    //     // TODO
    // } else if (call.method_name() == "getConfig") {
    //     // TODO
    // } else if (call.method_name() == "ackFlowEndedAndBackToIdle") {
    //     // TODO
    } else if (call.method_name() == "pair") {
        // TODO
        int _return_val = pair();
        if (_return_val == 0){
            result->Success("Successfully logged on.");
        }else{
            result->Error("PAIR_ERROR", "Unable to log on to EFTPOS PIN pad.");
        }
    // } else if (call.method_name() == "pairingConfirmCode") {
    //     // TODO
    // } else if (call.method_name() == "pairingCancel") {
    //     // TODO
    // } else if (call.method_name() == "unpair") {
    //     // TODO
    // } else if (call.method_name() == "initiatePurchaseTx") {
    //     // TODO
    // } else if (call.method_name() == "initiateRefundTx") {
    //     // TODO
    // } else if (call.method_name() == "acceptSignature") {
    //     // TODO
    // } else if (call.method_name() == "submitAuthCode") {
    //     // TODO
    // } else if (call.method_name() == "cancelTransaction") {
    //     // TODO
    // } else if (call.method_name() == "initiateCashoutOnlyTx") {
    //     // TODO
    // } else if (call.method_name() == "initiateMotoPurchaseTx") {
    //     // TODO
    // } else if (call.method_name() == "initiateSettleTx") {
    //     // TODO
    // } else if (call.method_name() == "initiateSettlementEnquiry") {
    //     // TODO
    // } else if (call.method_name() == "initiateGetLastTx") {
    //     // TODO
    // } else if (call.method_name() == "initiateRecovery") {
    //     // TODO
    // } else if (call.method_name() == "dispose") {
    //     // TODO
    // } else if (call.method_name() == "getDeviceSN") {
    //     // TODO
    // } else if (call.method_name() == "setPromptForCustomerCopyOnEftpos") {
    //     // TODO
    // } else if (call.method_name() == "setSignatureFlowOnEftpos") {
    //     // TODO
    // } else if (call.method_name() == "setPrintMerchantCopy") {
    //     // TODO
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

int FlutterSpiPlugin::start(){
    ptr = addr_result;

    s = INVALID_SOCKET;
    s = socket(ptr->ai_family, ptr->ai_socktype, ptr->ai_protocol);

    if (s == INVALID_SOCKET) {
        printf("Error at socket(): %d\n", WSAGetLastError());
        freeaddrinfo(addr_result);
        WSACleanup();
        return 1;
    }

    // Connect to server
    iResult = connect(s, ptr->ai_addr, (int)ptr->ai_addrlen);
    if (iResult == SOCKET_ERROR) {
        closesocket(s);
        s = INVALID_SOCKET;
    }

    freeaddrinfo(addr_result);

    if (s == INVALID_SOCKET) {
        printf("Unable to connect to server!\n");
        WSACleanup();
        return 1;
    }

    std::cout << "Connected!" << std::endl;
    return 0;
}

int FlutterSpiPlugin::pair(){
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

    iResult = send(s, &message[0], (int)message.size(), 0);
    if (iResult == SOCKET_ERROR) {
        printf("send failed: %d\n", iResult);
        close_connection();
        return 1;
    }

    do {
        iResult = recv(s, buffer, DEFAULT_BUFLEN, 0);
        if (iResult > 0){
            // printf("Bytes received: %d\n", iResult);
            
            std::cout << buffer << std::endl;
            char start_flag = buffer[0];
            if (start_flag != '#') {
                std::cout << "STRAT_FLAG does not match!"<< std::endl;
                return 1;
            }
            char command_code = buffer[5];
            if (command_code == 'G'){
                char success_flag = buffer[7];
                if (success_flag == '1'){
                    std::cout << "Log on successful!"<< std::endl;
                    return 0;
                }else{
                    std::cout << "Log on failed!"<< std::endl;
                    return 1;
                }
            }
        }
        else if (iResult == 0){
            // printf("Connection closed\n");
            // closesocket(s);
            // WSACleanup();
            break;
        }
        else{
            printf("recv failed: %d\n", WSAGetLastError());
            close_connection();
            return 1;
        }
    } while (true);

    return 0;
}

void FlutterSpiPlugin::close_connection(){
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

void FlutterSpiPlugin::update_message_length(std::vector<char>& message){
    // Update the length of message
    std::string message_len = std::to_string((int)message.size());

    int temp_len_i = 4;
    for (auto it = message_len.rbegin(); it != message_len.rend(); ++it, --temp_len_i){
        message[temp_len_i] = *it;
    }
}


}  // namespace flutter_spi
