#include "flutter_spi_plugin.h"

#define LINKLY_HOST "127.0.0.1"
#define LINKLY_PORT "2011"
#define DEFAULT_BUFLEN 1024

namespace flutter_spi {

// static
void FlutterSpiPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "flutter_spi",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<FlutterSpiPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
}

FlutterSpiPlugin::FlutterSpiPlugin() {}

FlutterSpiPlugin::~FlutterSpiPlugin() {}

void FlutterSpiPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (method_call.method_name() == "init") {
        // TODO
        int _return_val = init();
        if (_return_val == 0){
            result->Success(NULL);
        }else{
            result->Error("INIT_ERROR", "Socket initialisation failed.");
        }

    } else if (method_call.method_name() == "start") {
        // TODO
        int _return_val = start();
        if (_return_val == 0){
            result->Success(NULL);
        }else{
            result->Error("START_ERROR", "Socket connection failed.");
        }
    // } else if (method_call.method_name() == "setPosId") {
    //     // TODO
    // } else if (method_call.method_name() == "setSerialNumber") {
    //     // TODO
    // } else if (method_call.method_name() == "setEftposAddress") {
    //     // TODO
    // } else if (method_call.method_name() == "setPosInfo") {
    //     // TODO
    // } else if (method_call.method_name() == "getVersion") {
    //     // TODO
    // } else if (method_call.method_name() == "getCurrentStatus") {
    //     // TODO
    // } else if (method_call.method_name() == "getCurrentFlow") {
    //     // TODO
    // } else if (method_call.method_name() == "getCurrentPairingFlowState") {
    //     // TODO
    // } else if (method_call.method_name() == "getCurrentTxFlowState") {
    //     // TODO
    // } else if (method_call.method_name() == "getConfig") {
    //     // TODO
    // } else if (method_call.method_name() == "ackFlowEndedAndBackToIdle") {
    //     // TODO
    // } else if (method_call.method_name() == "pair") {
    //     // TODO
    // } else if (method_call.method_name() == "pairingConfirmCode") {
    //     // TODO
    // } else if (method_call.method_name() == "pairingCancel") {
    //     // TODO
    // } else if (method_call.method_name() == "unpair") {
    //     // TODO
    // } else if (method_call.method_name() == "initiatePurchaseTx") {
    //     // TODO
    // } else if (method_call.method_name() == "initiateRefundTx") {
    //     // TODO
    // } else if (method_call.method_name() == "acceptSignature") {
    //     // TODO
    // } else if (method_call.method_name() == "submitAuthCode") {
    //     // TODO
    // } else if (method_call.method_name() == "cancelTransaction") {
    //     // TODO
    // } else if (method_call.method_name() == "initiateCashoutOnlyTx") {
    //     // TODO
    // } else if (method_call.method_name() == "initiateMotoPurchaseTx") {
    //     // TODO
    // } else if (method_call.method_name() == "initiateSettleTx") {
    //     // TODO
    // } else if (method_call.method_name() == "initiateSettlementEnquiry") {
    //     // TODO
    // } else if (method_call.method_name() == "initiateGetLastTx") {
    //     // TODO
    // } else if (method_call.method_name() == "initiateRecovery") {
    //     // TODO
    // } else if (method_call.method_name() == "dispose") {
    //     // TODO
    // } else if (method_call.method_name() == "getDeviceSN") {
    //     // TODO
    // } else if (method_call.method_name() == "setPromptForCustomerCopyOnEftpos") {
    //     // TODO
    // } else if (method_call.method_name() == "setSignatureFlowOnEftpos") {
    //     // TODO
    // } else if (method_call.method_name() == "setPrintMerchantCopy") {
    //     // TODO
    } else {
        result->NotImplemented();
    }
}

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

bool FlutterSpiPlugin::WinsockInitialized() {
    SOCKET test = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (test == INVALID_SOCKET) {
        return false;
    }
    closesocket(test);
    return true;
}
}  // namespace flutter_spi
