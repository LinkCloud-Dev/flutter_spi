#include "flutter_spi_plugin.h"

namespace flutter_spi {

Linkly::Linkly() {}

// Linkly& Linkly::get_instance() {
//     static Linkly instance;

//     return instance;
// }

int Linkly::init() {
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

int Linkly::start() { return 0; }

int Linkly::pair() {
    ptr = addr_result;

    s = INVALID_SOCKET;
    s = socket(ptr->ai_family, ptr->ai_socktype, ptr->ai_protocol);

    if (s == INVALID_SOCKET) {
        pair_flow_changed(true, "ERROR: Error at socket():" + std::to_string(WSAGetLastError()), "UNPAIRED");
        printf("Error at socket(): %d\n", WSAGetLastError());
        freeaddrinfo(addr_result);
        WSACleanup();
        return 1;
    }
    // u_long mode = 1;
    // if (ioctlsocket(s, FIONBIO, &mode)){
    //     printf("ioctlsocket() error %d\n", WSAGetLastError());
    //     freeaddrinfo(addr_result);
    //     close_connection();
    //     return 1;
    // }

    // Connect to Linkly client
    iResult = connect(s, ptr->ai_addr, (int)ptr->ai_addrlen);
    if (iResult == SOCKET_ERROR) {
        pair_flow_changed(true, "ERROR: Unable to connect to server", "UNPAIRED");
        closesocket(s);
        freeaddrinfo(addr_result);
        s = INVALID_SOCKET;
        return 1;
    }

    if (s == INVALID_SOCKET) {
        pair_flow_changed(true, "ERROR: Unable to connect to server", "UNPAIRED");
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

        pair_flow_changed(true, "ERROR: pair initialisation send failed", "UNPAIRED");
        return 1;
    }

    do {
        iResult = recv(s, buffer, DEFAULT_BUFLEN, 0);
        std::cout << iResult << std::endl;
        if (iResult > 0) {
            // printf("Bytes received: %d\n", iResult);
            std::vector<char> buffer_vec(buffer, buffer + iResult);
            std::cout << buffer_vec.data() << std::endl;

            char start_flag = buffer_vec[0];
            if (start_flag != '#') {
                std::cout << "STRAT_FLAG does not match!" << std::endl;
                pair_flow_changed(true, "ERROR: STRAT_FLAG does not match!", "UNPAIRED");
                return 1;
            }

            // Check for event type
            // G: Log on event, read the response text and check if log on is successful
            // S: Display event, read the response text and pass it on to POS
            // 3: Print event, print receipt
            char command_code = buffer_vec[5];
            if (command_code == 'G') {
                char success_flag = buffer_vec[7];
                std::string res_text(buffer_vec.begin() + 10, buffer_vec.begin() + 30);
                res_text.erase(std::remove_if(res_text.begin(), res_text.end(), isspace), res_text.end());

                if (success_flag == '1') {
                    std::cout << "Log on successful!" << std::endl;
                    pair_flow_changed(true, "Connected!", "PAIRED_CONNECTED");
                    return 0;

                } else {
                    std::cout << "Log on failed!" << std::endl;

                    pair_flow_changed(true, "ERROR: " + res_text, "UNPAIRED");
                    return 1;
                }
            } else if (command_code == 'S') {
                std::cout << "Connecting" << std::endl;
                pair_flow_changed(false, "Connecting...", "PAIRED_CONNECTING");

                if (buffer_vec[56] == '1') {
                    iResult = send(s, "#0008Y00", 8, 0);
                    if (iResult == SOCKET_ERROR) {
                        pair_flow_changed(true, "ERROR: Confirm message send failed", "UNPAIRED");
                        printf("send failed: %d\n", iResult);
                        closesocket(s);
                        WSACleanup();
                        return 1;
                    }
                }

            } else if (command_code == '3') {
                // Don't print since log on does not need receipt
                iResult = send(s, "#00073 ", 7, 0);
                if (iResult == SOCKET_ERROR) {
                    pair_flow_changed(true, "ERROR: Receipt response failed", "UNPAIRED");
                    printf("send failed: %d\n", iResult);
                    closesocket(s);
                    WSACleanup();
                    return 1;
                }
            }
        } else if (iResult == 0) {
            pair_flow_changed(true, "ERROR: Connection closed", "UNPAIRED");
            printf("Connection closed\n");
            close_connection();
            return 1;
        } else {
            pair_flow_changed(true, "ERROR: recv failed" + std::to_string(WSAGetLastError()), "UNPAIRED");
            printf("recv failed: %d\n", WSAGetLastError());
            close_connection();
            return 1;
        }
    } while (true);

    return 0;
}

int Linkly::init_purchase(std::string reference, int purchase_amount, int cashout_amount) {
    std::vector<char> message;
    char buffer[DEFAULT_BUFLEN];

    curr_ref = reference;

    std::string reference_short = reference.substr(0, 16);

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
    std::string cash_str = std::to_string(cashout_amount);
    for (int i = 0; i < 9 - cash_str.size(); i++) {
        message.push_back('0');
    }
    for (char c : cash_str) {
        message.push_back(c);
    }

    // Amount purchase
    std::string purchase_str = std::to_string(purchase_amount);
    for (int i = 0; i < 9 - purchase_str.size(); i++) {
        message.push_back('0');
    }
    for (char c : purchase_str) {
        message.push_back(c);
    }

    // Auth code
    message.insert(message.end(), 6, ' ');

    // Transaction reference
    for (char c : reference_short) {
        message.push_back(c);
    }

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
    message.insert(message.end(), 12, ' ');

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

    std::cout << message.data() << std::endl;
    iResult = send(s, message.data(), (int)message.size(), 0);
    if (iResult == SOCKET_ERROR) {
        transac_flow_changed(true, "ERROR: send failed: " + std::to_string(iResult), "FAILED");

        printf("send failed: %d\n", iResult);
        closesocket(s);
        WSACleanup();
        return 1;
    }

    std::string receipt = "";
    std::string receipt_type = "MERCHANT";

    do {
        iResult = recv(s, buffer, DEFAULT_BUFLEN, 0);
        if (iResult > 0) {
            std::vector<char> buffer_vec(buffer, buffer + iResult);

            std::cout << buffer_vec.data() << std::endl;

            char start_flag = buffer_vec[0];
            if (start_flag != '#') {
                std::cout << "STRAT_FLAG does not match!" << std::endl;
                transac_flow_changed(true, "ERROR: STRAT_FLAG does not match!", "FAILED");
                return 1;
            }

            // Check for event type
            // M: Transaction event, read the response text and check if transaction is successful
            // S: Display event, read the response text and pass it on to POS
            // 3: Receipt event, print receipt
            char command_code = buffer_vec[5];
            if (command_code == 'M') {
                char success_flag = buffer_vec[7];

                std::string res_text(buffer_vec.begin() + 10, buffer_vec.begin() + 30);

                std::string res_code(buffer_vec.begin() + 8, buffer_vec.begin() + 10);

                reference = std::string(buffer_vec.begin() + 73, buffer_vec.begin() + 89);

                if (success_flag == '1') {
                    std::cout << "Transaction successful!" << std::endl;
                    transac_flow_changed(true, res_text, "SUCCESS", receipt);
                    return 0;

                } else {

                    transac_flow_changed(true, res_text, "FAILED", receipt);
                    // Operator cancelled
                    if (res_code == "TM") {
                        return 0;
                    }
                    return 1;
                }
            } else if (command_code == 'S') {
                std::string res_text(buffer_vec.begin() + 11, buffer_vec.begin() + 50);

                allow_cancel = buffer_vec[51] == '1';

                transac_flow_changed(false, res_text, "");

                if (buffer_vec[56] == '1') {
                    iResult = send(s, "#0008Y00", 8, 0);
                    if (iResult == SOCKET_ERROR) {
                        transac_flow_changed(true, "ERROR: Confirm response send failed", "FAILED");
                        printf("send failed: %d\n", iResult);
                        closesocket(s);
                        WSACleanup();
                        return 1;
                    }
                }

            } else if (command_code == '3') {
                char sub_code = buffer_vec[6];
                if (sub_code == 'M') {
                    receipt_type = "MERCHANT";
                } else if (sub_code == 'C') {
                    receipt_type = "CUSTOMER";
                } else if (sub_code == 'R') {
                    // Store Receipt
                    receipt = std::string(buffer_vec.begin() + 7, buffer_vec.end());
                }
                iResult = send(s, "#00073 ", 7, 0);
                if (iResult == SOCKET_ERROR) {
                    transac_flow_changed(false, "ERROR: receipt response failed", "FAILED");
                    printf("send failed: %d\n", iResult);
                    closesocket(s);
                    WSACleanup();
                    return 1;
                }
            }
        } else if (iResult == 0) {
            transac_flow_changed(true, "ERROR: Connection closed", "FAILED");
            printf("Connection closed\n");
            close_connection();
            return 1;
        } else {
            transac_flow_changed(true, "ERROR: recv failed: " + std::to_string(WSAGetLastError()), "FAILED");
            printf("recv failed: %d\n", WSAGetLastError());
            close_connection();
            return 1;
        }
    } while (true);

    return 0;
}

int Linkly::cancel_transaction() {
    if (allow_cancel) {
        iResult = send(s, "#0008Y00", 8, 0);
        if (iResult == SOCKET_ERROR) {
            printf("send failed: %d\n", iResult);
            closesocket(s);
            WSACleanup();
            return 1;
        }
        std::unique_ptr<flutter::EncodableValue> transac_flow_state = std::make_unique<flutter::EncodableValue>(
            mapTransactionState(curr_ref, transaction_type, false, "", "", "", "", true));
        FlutterSpiPlugin::channel->InvokeMethod("txFlowStateChanged", std::move(transac_flow_state));

        return 0;
    } else {
        return 1;
    }
}

void Linkly::pair_flow_changed(bool finished, std::string flow_text, std::string status_text) {
    std::unique_ptr<flutter::EncodableValue> pair_flow_state =
        std::make_unique<flutter::EncodableValue>(mapPairingFlowState(flow_text, finished));
    FlutterSpiPlugin::channel->InvokeMethod("pairingFlowStateChanged", std::move(pair_flow_state));
    std::unique_ptr<flutter::EncodableValue> status = std::make_unique<flutter::EncodableValue>(status_text);
    FlutterSpiPlugin::channel->InvokeMethod("statusChanged", std::move(status));
}

void Linkly::transac_flow_changed(bool finished, std::string flow_text, std::string is_success, std::string receipt,
                                  bool cancel, bool sign_check, std::string sign_msg) {
    std::unique_ptr<flutter::EncodableValue> transac_flow_state = std::make_unique<flutter::EncodableValue>(
        mapTransactionState(curr_ref, transaction_type, finished, is_success, flow_text, receipt, flow_text, cancel,
                            sign_check, sign_msg));
    FlutterSpiPlugin::channel->InvokeMethod("txFlowStateChanged", std::move(transac_flow_state));
}

void Linkly::close_connection() {
    std::unique_ptr<flutter::EncodableValue> status = std::make_unique<flutter::EncodableValue>("UNPAIRED");
    FlutterSpiPlugin::channel->InvokeMethod("statusChanged", std::move(status));
    freeaddrinfo(addr_result);
    closesocket(s);
    WSACleanup();
}

bool Linkly::WinsockInitialized() {
    SOCKET test = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (test == INVALID_SOCKET) {
        return false;
    }
    closesocket(test);
    return true;
}

void Linkly::update_message_length(std::vector<char>& message) {
    // Update the length of message
    std::string message_len = std::to_string((int)message.size());

    int temp_len_i = 4;
    for (auto it = message_len.rbegin(); it != message_len.rend(); ++it, --temp_len_i) {
        message[temp_len_i] = *it;
    }
}

flutter::EncodableValue Linkly::mapPairingFlowState(std::string message, bool finished) {
    std::map<flutter::EncodableValue, flutter::EncodableValue> map;
    map[flutter::EncodableValue("message")] = flutter::EncodableValue(message);
    map[flutter::EncodableValue("awaitingCheckFromEftpos")] = flutter::EncodableValue(false);
    map[flutter::EncodableValue("awaitingCheckFromPos")] = flutter::EncodableValue(false);
    map[flutter::EncodableValue("confirmationCode")] = flutter::EncodableValue("");
    map[flutter::EncodableValue("finished")] = flutter::EncodableValue(finished);
    map[flutter::EncodableValue("successful")] = flutter::EncodableValue(false);

    return flutter::EncodableValue(map);
}

flutter::EncodableValue Linkly::mapTransactionState(std::string reference, std::string type, bool finished,
                                                    std::string success, std::string message, std::string receipt,
                                                    std::string display_message, bool attempt_to_cancel,
                                                    bool awaitingSignatureCheck, std::string signature_message) {
    std::map<flutter::EncodableValue, flutter::EncodableValue> map;
    map[flutter::EncodableValue("posRefId")] = flutter::EncodableValue(reference);
    map[flutter::EncodableValue("type")] = flutter::EncodableValue(type);                       // Needed
    map[flutter::EncodableValue("displayMessage")] = flutter::EncodableValue(display_message);  // Needed
    map[flutter::EncodableValue("amountCents")] = flutter::EncodableValue(100);
    map[flutter::EncodableValue("requestSent")] = flutter::EncodableValue(false);
    map[flutter::EncodableValue("requestTime")] = flutter::EncodableValue();
    map[flutter::EncodableValue("lastStateRequestTime")] = flutter::EncodableValue();
    map[flutter::EncodableValue("attemptingToCancel")] = flutter::EncodableValue(attempt_to_cancel);           // Needed
    map[flutter::EncodableValue("awaitingSignatureCheck")] = flutter::EncodableValue(awaitingSignatureCheck);  // Needed
    map[flutter::EncodableValue("awaitingPhoneForAuth")] = flutter::EncodableValue(false);
    map[flutter::EncodableValue("finished")] = flutter::EncodableValue(finished);  // Needed
    map[flutter::EncodableValue("success")] = flutter::EncodableValue(success);    // Needed
    map[flutter::EncodableValue("response")] =
        flutter::EncodableValue(mapMessage(message, receipt, type == "SETTLE" || type == "REFUND"));  // Needed
    map[flutter::EncodableValue("signatureRequiredMessage")] = flutter::EncodableValue();             // Needed
    map[flutter::EncodableValue("phoneForAuthRequiredMessage")] = flutter::EncodableValue();
    map[flutter::EncodableValue("cancelAttemptTime")] = flutter::EncodableValue();
    map[flutter::EncodableValue("request")] = flutter::EncodableValue();
    map[flutter::EncodableValue("awaitingGltResponse")] = flutter::EncodableValue(false);

    return flutter::EncodableValue(map);
}

flutter::EncodableValue Linkly::mapMessage(std::string message, std::string receipt, bool is_refund_or_settle) {
    std::map<flutter::EncodableValue, flutter::EncodableValue> data;
    std::map<flutter::EncodableValue, flutter::EncodableValue> map;

    // Map data
    if (!is_refund_or_settle) {
        if (receipt.size() != 0) {
            data[flutter::EncodableValue("customer_receipt")] = flutter::EncodableValue(receipt);
        } else {
            data[flutter::EncodableValue("customer_receipt")] = flutter::EncodableValue();
        }
        data[flutter::EncodableValue("host_response_text")] = flutter::EncodableValue(message);
    } else {
        if (receipt.size() != 0) {
            data[flutter::EncodableValue("merchant_receipt")] = flutter::EncodableValue(receipt);
        } else {
            data[flutter::EncodableValue("merchant_receipt")] = flutter::EncodableValue();
        }
        data[flutter::EncodableValue("host_response_code")] = flutter::EncodableValue("001");
    }

    // Map message
    map[flutter::EncodableValue("id")] = flutter::EncodableValue();
    map[flutter::EncodableValue("event")] = flutter::EncodableValue();
    map[flutter::EncodableValue("data")] = flutter::EncodableValue(data);

    return flutter::EncodableValue(map);
}
}  // namespace flutter_spi