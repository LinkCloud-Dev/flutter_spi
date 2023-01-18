#include "flutter_spi_plugin.h"

namespace flutter_spi {

WSADATA Linkly::wsa;
SOCKET Linkly::s;
struct sockaddr_in Linkly::server;

int Linkly::iResult;
struct addrinfo *Linkly::addr_result, *Linkly::ptr, Linkly::hints;

std::string Linkly::transaction_type = "";
std::string Linkly::curr_ref = "";
bool Linkly::allow_cancel = false;

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> FlutterSpiPlugin::channel;
// std::thread FlutterSpiPlugin::thread;
// static
void FlutterSpiPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
    channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "flutter_spi", &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<FlutterSpiPlugin>();


    channel->SetMethodCallHandler([plugin_pointer = plugin.get()](const auto& call, auto result) {
        if (call.method_name() == "init") {
            // TODO
            int _return_val = Linkly::init();
            if (_return_val == 0) {
                result->Success("Socket initialised.");
            } else {
                result->Error("INIT_ERROR", "Socket initialisation failed.");
            }

        } else if (call.method_name() == "start") {
            int _return_val = Linkly::start();
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

            std::thread thread = std::thread(Linkly::pair);
            thread.detach();
            int _return_val = 0;
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
            Linkly::close_connection();
            result->Success("Successfully cancelled.");
        } else if (call.method_name() == "initiatePurchaseTx") {
            // Amount here is passed by in form of at least 4 digits integer or 0
            // e.g. 15 dollars of purchase is passed as 1500
            // 0 dollars of cashout amount is passed as 0
            const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
            const auto* purchase_amount = std::get_if<int>(ValueOrNull(*arguments, "purchaseAmount"));
            const auto* cashout_amount = std::get_if<int>(ValueOrNull(*arguments, "cashoutAmount"));
            const auto* reference = std::get_if<std::string>(ValueOrNull(*arguments, "posRefId"));

            Linkly::transaction_type = "PURCHASE";
            std::thread thread = std::thread(Linkly::init_purchase, *reference, *purchase_amount, *cashout_amount);
            thread.detach();

            int _return_val = 0;

            if (_return_val == 0) {
                result->Success("Purchase complete.");
            } else {
                result->Error("PURCHASE_ERROR", "Unable to finish purchase transaction.");
            }

            // } else if (call.method_name() == "initiateRefundTx") {
            //     // TODO
            // } else if (call.method_name() == "acceptSignature") {
            //     // TODO
        } else if (call.method_name() == "cancelTransaction") {
            int _return_val = Linkly::cancel_transaction();
            if (_return_val == 0) {
                result->Success("Purchase complete.");
            } else {
                result->Error("PURCHASE_ERROR", "Unable to finish purchase transaction.");
            }
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
}  // namespace flutter_spi

const flutter::EncodableValue* ValueOrNull(const flutter::EncodableMap& map, const char* key) {
    auto it = map.find(flutter::EncodableValue(key));
    if (it == map.end()) {
        return nullptr;
    }
    return &(it->second);
}
