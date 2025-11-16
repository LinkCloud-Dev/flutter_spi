import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

enum ANZConnectionStatus {
  disconnected,    // TIM API: DISCONNECTED
  loggedIn,        // TIM API: LOGGED_IN
  loggedOut,       // TIM API: LOGGED_OUT
}

enum ANZTransactionStatus {
  idle,           // 空闲状态
  processing,     // 交易处理中
  completed,      // 交易完成
  failed,         // 交易失败 (包括取消、错误等)
}

enum ANZUnpairStatus {
  idle,
  disposed,
  failed,
}

enum ANZPairingFlowStatus { // Pairing Flow Status defined by LinkPOS
  idle,          
  connected,
  loggedIn,
  activated,      
  
  connecting,     
  loggingIn,     
  activating,    
  failed,         
}
class ANZTransactionData {
  final String? posRefId;
  final int? amountInCents;
  final int? amountExponent;
  final String? currency;
  final int? surchargeAmount;
  final int? surchargeExponent;
  final String? transactionType;
  final String? transRef;
  final String? transSeq;
  final String? acqId;
  final String? acqTransRef;
  final String? sixTrxRefNum;
  // Structured receipts: each has { recipient, value }
  final List<Map<String, String>>? receipts;
  final String? errorMessage;

  ANZTransactionData({
    this.posRefId,
    this.amountInCents,
    this.amountExponent,
    this.currency,
    this.surchargeAmount,
    this.surchargeExponent,
    this.transactionType,
    this.transRef,
    this.transSeq,
    this.acqId,
    this.acqTransRef,
    this.sixTrxRefNum,
    this.receipts,
    this.errorMessage,
  });

  factory ANZTransactionData.fromMap(Map<String, dynamic> map) {
    // Calculate actual amounts using exponent
    final amountInCents = map['amountInCents'] as int?;
    final amountExponent = map['amountExponent'] as int?;

    final surchargeAmount = map['surchargeAmount'] as int?;
    final surchargeExponent = map['surchargeExponent'] as int?;

    return ANZTransactionData(
      posRefId: map['posRefId']?.toString(),
      amountInCents: amountInCents,
      amountExponent: amountExponent,
      currency: map['currency']?.toString(),
      surchargeAmount: surchargeAmount,
      surchargeExponent: surchargeExponent,
      transactionType: map['transactionType']?.toString(),
      transRef: map['transRef']?.toString(),
      transSeq: map['transSeq']?.toString(),
      acqId: map['acqId']?.toString(),
      acqTransRef: map['acqTransRef']?.toString(),
      sixTrxRefNum: map['sixTrxRefNum']?.toString(),
      receipts: map['receipts'] != null
          ? (map['receipts'] as List)
              .where((e) => e != null)
              .map((e) {
                final m = Map<String, dynamic>.from(e as Map);
                return {
                  'recipient': (m['recipient'] ?? '').toString(),
                  'value': (m['value'] ?? '').toString(),
                };
              })
              .toList()
          : null,
      errorMessage: map['errorMessage']?.toString(),
    );
  }

  factory ANZTransactionData.error(String errorMessage) {
    return ANZTransactionData(errorMessage: errorMessage);
  }

  // Helper method to get formatted amount string
  String? get formattedAmount {
    if (amountInCents != null && amountExponent != null ) {
      final actualAmount = amountInCents! / pow(10, amountExponent!);
      return '${actualAmount.toStringAsFixed(2)}';
    }
    return null;
  }

  // Helper method to get formatted surcharge string
  String? get formattedSurcharge {
    if (surchargeAmount != null && surchargeExponent != null) {
      final actualSurchargeAmount = surchargeAmount! / pow(10, surchargeExponent!);
      return '${actualSurchargeAmount.toStringAsFixed(2)}';
    }
    return null;
  }
}

class AnzState extends ChangeNotifier {

  ANZConnectionStatus _connectionStatus = ANZConnectionStatus.disconnected;
  ANZConnectionStatus get connectionStatus => _connectionStatus;
  
  ANZPairingFlowStatus _pairingFlowStatus = ANZPairingFlowStatus.idle;
  ANZPairingFlowStatus get pairingFlowStatus => _pairingFlowStatus;

  ANZTransactionStatus _transactionStatus = ANZTransactionStatus.idle;
  ANZTransactionStatus get transactionStatus => _transactionStatus;
  
  ANZTransactionData? _lastTransaction;
  ANZTransactionData? get lastTransaction => _lastTransaction;
  
  List<Map<String, String>>? _balanceReceipts;
  List<Map<String, String>>? get balanceReceipts => _balanceReceipts;

  ANZUnpairStatus _unpairStatus = ANZUnpairStatus.idle;
  ANZUnpairStatus get unpairStatus => _unpairStatus;

  // Idempotent guards
  bool _eventsSubscribed = false;
  StreamSubscription<dynamic>? _eventSubscription;

    // 配对超时相关变量
  // DateTime? _pairingStepStartTime; // tracked via timer only
  static const int _pairingStepTimeoutSeconds = 60; // 1分钟超时
  Timer? _pairingTimeoutTimer;
  
  // 添加标志来跟踪是否正在进行 balance 操作
  bool _isBalanceInProgress = false;
  bool get isBalanceInProgress => _isBalanceInProgress;

Future<void> initTerminal(context) async {    
    // If already logged in, skip timApiInit. Otherwise, ensure TIM API is initialised.
    if (_connectionStatus == ANZConnectionStatus.loggedIn) {
      print('⏭️ Already LOGGED_IN, skip timApiInit');
    } else {
      await FlutterSpi.init(
        spiType: "ANZ",
        enablePrinting: false,
      );
      print('✅ TIM API initialised');
    }

    _subscribeTimEvents();
  }

void _updatePairingFlowStatus(ANZPairingFlowStatus newStatus) {
    if (_pairingFlowStatus != newStatus) {
      print("🔄 Pairing flow status changed: ${_pairingFlowStatus.name} -> ${newStatus.name}");
      _pairingFlowStatus = newStatus;
      
      _handlePairingStepTimeout(newStatus);
      
      notifyListeners();
    }
  }

  void _handlePairingStepTimeout(ANZPairingFlowStatus newStatus) {
    // 取消之前的计时器
    _pairingTimeoutTimer?.cancel();
    _pairingTimeoutTimer = null;
    
    // 检查是否是需要计时的中间状态
    final timeoutStates = [
      ANZPairingFlowStatus.connecting,
      ANZPairingFlowStatus.loggingIn,
      ANZPairingFlowStatus.activating,
    ];
    
    if (timeoutStates.contains(newStatus)) {
      // 开始计时
      _pairingTimeoutTimer = Timer(Duration(seconds: _pairingStepTimeoutSeconds), () {
        print("⏰ Pairing step timeout: ${newStatus.name} exceeded ${_pairingStepTimeoutSeconds} seconds");
        _updatePairingFlowStatus(ANZPairingFlowStatus.failed);
        EasyLoading.showToast(
          "Pairing step timeout: ${newStatus.name} exceeded ${_pairingStepTimeoutSeconds} seconds",
          duration: Duration(seconds: 3),
        );
      });
      print("⏰ Started timeout timer for ${newStatus.name} (${_pairingStepTimeoutSeconds}s)");
    } else {
      // 清除计时器
    }
  }

  void _updateUnpairStatus(ANZUnpairStatus newStatus) {
    _unpairStatus = newStatus;
    notifyListeners();
  }

  void _updateConnectionStatus(ANZConnectionStatus newStatus) {
    _connectionStatus = newStatus;
    notifyListeners();
  }

  void _updateTransactionStatus(ANZTransactionStatus newStatus) {
    _transactionStatus = newStatus;
    notifyListeners();
  }

    // -----------------------------------------Unpairing Flow-----------------------------------------
  // Unpairing flow: startDeactivate -> handleDeactivateCompleted -> handleLogoutCompleted -> handleDisposed
  Future<void> startDeactivate() async {
    try {
      _isBalanceInProgress = false;
      await FlutterSpi.timApiDeactivate();
    } catch (e) {
      print('❌ Start deactivate failed: $e');
      _updateUnpairStatus(ANZUnpairStatus.failed);
    }
  }

  void _resetTransactionState() {
    _updateTransactionStatus(ANZTransactionStatus.idle);
    _lastTransaction = null;
  }

  void clearError() {
    _lastTransaction = null;
    _updateTransactionStatus(ANZTransactionStatus.idle);
    notifyListeners();
  }
  // -----------------------------------------Event Subscription-----------------------------------------

  void _subscribeTimEvents() {
    if (_eventsSubscribed) return;
    _eventsSubscribed = true;
    _eventSubscription = FlutterSpi.eventStream.listen((event) {
      final eventMap = Map<String, dynamic>.from(event);
      final eventType = eventMap['type'] as String?;

      switch (eventType) {
        case 'connectCompleted':
          _handleConnectCompleted(eventMap);
          break;
        case 'loginCompleted':
          _handleLoginCompleted(eventMap);
          break;
        case 'activateCompleted':
          _handleActivateCompleted(eventMap);
          break;
        case 'terminalStatusChanged':
          _handleTerminalStatusChanged(eventMap);
          break;
        case 'transactionCompleted':
          _handleTransactionCompleted(eventMap);
          break;
        case 'balanceCompleted':
          _handleBalanceCompleted(eventMap);
          _isBalanceInProgress = false;
          break;
        case 'deactivateCompleted':
          if (!_isBalanceInProgress) {
            FlutterSpi.timApiLogout();
          }
          break;
        case 'logoutCompleted':
          if (!_isBalanceInProgress) {
            FlutterSpi.timApiDisconnect();
          }
          break;
        case 'disconnected':
          _handleDisconnected(eventMap);
          break;
        case 'disposed':
          _handleDisposed(eventMap);
          notifyListeners();
          break;
        case 'unpairError':
          _updateUnpairStatus(ANZUnpairStatus.failed);
          notifyListeners();
          break;
        case 'error':
          _handleError(eventMap);
          break;
        default:
          print("⚠️ 未处理事件类型: $eventType");
      }
    });
  }


  // -------------------------------------------------------------Pairing Flow-----------------------------------------------------------
  // Pairing flow: startConnection -> handleConnectCompleted -> startLogin -> handleLoginCompleted -> startActivation -> handleActivateCompleted
  


  Future<void> startConnection() async { // the first step of pairing flow, trigger by Users in Eftpos setting or autoPair()
    try {
      print("✅ Starting connection...");
      _updatePairingFlowStatus(ANZPairingFlowStatus.connecting);
      await FlutterSpi.timApiConnect();
    } catch (e) {
      print("❌ Connect failed: $e");
      _updatePairingFlowStatus(ANZPairingFlowStatus.failed);
      await _requestCurrentStatus();
    }
  }

  Future<void> startLogin() async { 
    try {
      print("✅ Starting login...");
      _updatePairingFlowStatus(ANZPairingFlowStatus.loggingIn);
      await FlutterSpi.timApiLogin();
    } catch (e) {
      print("❌ Login failed: $e");
      _updatePairingFlowStatus(ANZPairingFlowStatus.failed);
      await _requestCurrentStatus();
    }
  }

  Future<void> startActivation() async { 
    try {
      print("✅ Starting activation...");
      _updatePairingFlowStatus(ANZPairingFlowStatus.activating);
      await FlutterSpi.timApiActivate();
    } catch (e) {
      print("❌ Activation failed: $e");
      _updatePairingFlowStatus(ANZPairingFlowStatus.failed);
      await _requestCurrentStatus();
    }
  }


  // Pairing flow event handlers
  void _handleConnectCompleted(Map<String, dynamic> event) async {
    if (event['status'] == 'success') {

      _updatePairingFlowStatus(ANZPairingFlowStatus.connected);
      
      await startLogin();
    } else {
      _updatePairingFlowStatus(ANZPairingFlowStatus.failed);
      
      await _requestCurrentStatus();
    }
  }

  void _handleLoginCompleted(Map<String, dynamic> event) async {
    if (event['status'] == 'success') {

      _updatePairingFlowStatus(ANZPairingFlowStatus.loggedIn);
      
      await startActivation();
    } else {
      _updatePairingFlowStatus(ANZPairingFlowStatus.failed);
      
      await _requestCurrentStatus();
    }
  }

  void _handleActivateCompleted(Map<String, dynamic> event) async {
    if (event['status'] == 'success') {
      _updatePairingFlowStatus(ANZPairingFlowStatus.activated);
    } else {
      _updatePairingFlowStatus(ANZPairingFlowStatus.failed);

      await _requestCurrentStatus();
    }
  }



  // Terminal status event handlers
  void _handleTerminalStatusChanged(Map<String, dynamic> event) {
    final connectionStatus = event['connectionStatus'] as String?;

    print("📊 TIM API ConnectionStatus: $connectionStatus");

    if (connectionStatus != null) {
      switch (connectionStatus) {
        case 'DISCONNECTED':
          _updateConnectionStatus(ANZConnectionStatus.disconnected);
          // 只有在配对流程不在进行中时才重置为 idle
          if (!isWaitingForPairingResult) {
            _updatePairingFlowStatus(ANZPairingFlowStatus.idle);
          }
          _updateUnpairStatus(ANZUnpairStatus.idle);
          break;
        case 'LOGGED_IN':
          _updateConnectionStatus(ANZConnectionStatus.loggedIn);
          _updateUnpairStatus(ANZUnpairStatus.idle);
          break;
        case 'LOGGED_OUT':
          _updateConnectionStatus(ANZConnectionStatus.loggedOut);
          if (!isWaitingForPairingResult) {
            _updatePairingFlowStatus(ANZPairingFlowStatus.idle);
          }
          _updateUnpairStatus(ANZUnpairStatus.idle);
          break;
        default:
          print("⚠️ Unknown TIM API connection status: $connectionStatus");
      }
    }
  }



    // -------------------------------------------------------------Transaction Flow-----------------------------------------------------------
  // Transaction methods: startTransaction, startRefund, startBalance, startReversal
  Future<void> startTransaction(String posRefId, double amount) async {
    if (_connectionStatus != ANZConnectionStatus.loggedIn) { //TODO: check later
      _lastTransaction = ANZTransactionData.error("Terminal not ready for transaction");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      EasyLoading.showToast( 
        "Terminal not ready for transaction",
        duration: Duration(seconds: 3),
      );
      return;
    }
    _resetTransactionState();

    try {
      _updateTransactionStatus(ANZTransactionStatus.processing);
      await FlutterSpi.timApiCharge(amount);
    } catch (e) {
      print("❌ Start transaction failed: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      _lastTransaction = ANZTransactionData.error("Failed to start transaction: $e");
      print("   Error type: ${e.runtimeType}");
      print("   Error message: $e");
      print("   Stack trace: ${e is Error ? e.stackTrace : 'No stack trace available'}");
    }
  }

  Future<void> startRefund(String posRefId, double amount) async {
    if (_connectionStatus != ANZConnectionStatus.loggedIn) {
      print("❌ Terminal not ready for refund");
      return;
    }

    _resetTransactionState();

    try {
      _updateTransactionStatus(ANZTransactionStatus.processing);
      await FlutterSpi.timApiRefund(amount);
    } catch (e) {
      print("❌ Start refund failed: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      _lastTransaction = ANZTransactionData.error("Failed to start refund: $e");
    }
  }
  
  Future<void> startReferenceRefund(
    String posRefId, 
    double amount, 
    String sixTrxRefNum,
  ) async {
    if (_pairingFlowStatus != ANZPairingFlowStatus.activated) {
      print("❌ Terminal not ready for reference refund");
      return;
    }

    _resetTransactionState();

    try {
      // _currentTransactionId = posRefId;
      _updateTransactionStatus(ANZTransactionStatus.processing);
      await FlutterSpi.timApiRefRefund(
        amount: amount,
        sixTrxRefNum: sixTrxRefNum,
      );
    } catch (e) {
      print("❌ Start reference refund failed: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      _lastTransaction = ANZTransactionData.error("Failed to start reference refund: $e");
    }
  }


  Future<void> startBalance() async {
    if (_connectionStatus != ANZConnectionStatus.loggedIn) {
      EasyLoading.showToast(
        "Terminal not ready for balance",
        duration: Duration(seconds: 3),
      );
      return;
    }

    _resetTransactionState();

    try {
      _updateTransactionStatus(ANZTransactionStatus.processing);
      _isBalanceInProgress = true;
      await FlutterSpi.timApiBalance();
    } catch (e) {
      print("❌ Start balance failed: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      _lastTransaction = ANZTransactionData.error("Failed to start balance: $e");
      _isBalanceInProgress = false;
      await _requestCurrentStatus();
      notifyListeners();
    }
  }

  Future<void> startReversal() async {
    if (_pairingFlowStatus != ANZPairingFlowStatus.activated) {
      print("❌ Terminal not ready for reversal");
      return;
    }
    if (_lastTransaction?.transSeq == null) {
      print("❌ No previous transaction to reverse");
      return;
    }
    try {
      _updateTransactionStatus(ANZTransactionStatus.processing);
      await FlutterSpi.timApiReversal(transSeq: _lastTransaction!.transSeq!);
    } catch (e) {
      print("❌ Start reversal failed: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      _lastTransaction = ANZTransactionData.error("Failed to start reversal: $e");
    }
  }

  void _handleDisconnected(Map<String, dynamic> event) {
    //TODO: check later
    // reset all status
    // _updateConnectionStatus(ANZConnectionStatus.disconnected);
    // _updateTransactionStatus(ANZTransactionStatus.idle);
    // _updatePairStatus(ANZPairStatus.disconnected);
    // _updateUnpairStatus(ANZUnpairStatus.idle);
    // _currentTransactionId = null;
  }

  // Unpairing flow event handlers
  Future<void> _handleDisposed(Map<String, dynamic> event) async {
    if (event['status'] == 'success') {
      _updateUnpairStatus(ANZUnpairStatus.disposed);
      _updateConnectionStatus(ANZConnectionStatus.disconnected);
      _updatePairingFlowStatus(ANZPairingFlowStatus.idle);
      _lastTransaction = null;
      // next initTerminal will check connectionStatus and re-initialize if needed

    } else {
      _updateUnpairStatus(ANZUnpairStatus.failed);
      await _requestCurrentStatus();
      notifyListeners();
    }
  }

  void _handleTransactionCompleted(Map<String, dynamic> event) {
    print("✅ Transaction completed: $event");
    
    try {
      print("🔍 Parsing transaction data:");
      print("  - amountInCents: ${event['amountInCents']} (${event['amountInCents']?.runtimeType})");
      print("  - amountExponent: ${event['amountExponent']} (${event['amountExponent']?.runtimeType})");
      print("  - currency: ${event['currency']} (${event['currency']?.runtimeType})");
      print("  - surchargeAmount: ${event['surchargeAmount']} (${event['surchargeAmount']?.runtimeType})");
      print("  - surchargeExponent: ${event['surchargeExponent']} (${event['surchargeExponent']?.runtimeType})");
      print("  - transactionType: ${event['transactionType']} (${event['transactionType']?.runtimeType})");
      print("  - transRef: ${event['transRef']} (${event['transRef']?.runtimeType})");
      print("  - transSeq: ${event['transSeq']} (${event['transSeq']?.runtimeType})");
      print("  - acqId: ${event['acqId']} (${event['acqId']?.runtimeType})");
      print("  - acqTransRef: ${event['acqTransRef']} (${event['acqTransRef']?.runtimeType})");
      print("  - sixTrxRefNum: ${event['sixTrxRefNum']} (${event['sixTrxRefNum']?.runtimeType})");
      print("  - receipts: ${event['receipts']} (${event['receipts']?.runtimeType})");
      
      _lastTransaction = ANZTransactionData.fromMap(event);
      _updateTransactionStatus(ANZTransactionStatus.completed);
      // _currentTransactionId = null;
    } catch (e) {
      print("❌ Error parsing transaction data: $e");
      print("❌ Stack trace: ${StackTrace.current}");
      _lastTransaction = ANZTransactionData.error("Error parsing transaction data: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
    }
  }



    // -------------------------------------------------------------Balance Flow-----------------------------------------------------------
  void _handleBalanceCompleted(Map<String, dynamic> event) {
    print("✅ Balance completed: $event");
    print("  - receipts: ${event['receipts']} (${event['receipts']?.runtimeType})");

    // 存储结构化收据信息
    final receipts = event['receipts'] as List<dynamic>?;
    if (receipts != null && receipts.isNotEmpty) {
      _balanceReceipts = receipts.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'recipient': (m['recipient'] ?? '').toString(),
          'value': (m['value'] ?? '').toString(),
        };
      }).toList();
      notifyListeners();
    }
  }

  void clearBalanceReceipts() {
    _balanceReceipts = null;
    notifyListeners();
  }


  void _handleError(Map<String, dynamic> event) {
    final source = event['source'] as String?;
    final message = event['message'] as String? ?? "Unknown error";
    final resultCode = event['resultCode'] as String?;
    final localizedMessage = event['localizedMessage'] as String?;
    print('.......show localizedMessage${localizedMessage}');


    if (_isCommunicationError(message, resultCode)) {
      print("🔄 检测到communication错误，自动重置状态: $message (resultCode: $resultCode)");
      _resetStatusForCommunicationError(message);
    }

    // Here only showing error, do not dealing with any status change
    if (_isRequestError(message, resultCode)) {
      print("🔄 检测到request错误: $message (resultCode: $resultCode)");
      EasyLoading.showToast(
        "${localizedMessage.toString()}，please check terminal.",
        duration: Duration(seconds: 3),
      );
    }

    if (source == 'transactionCompleted') {
      print("🔄 检测到transactionCompleted错误: $message (resultCode: $resultCode)");
      _lastTransaction = ANZTransactionData.error(message);
      _updateTransactionStatus(ANZTransactionStatus.failed);
      // return;
    }

    // Other errors
    EasyLoading.showToast(
      "${localizedMessage.toString()}",
      duration: Duration(seconds: 3),
    );
    print('.......show localizedMessage${localizedMessage}');
  }


  bool _isCommunicationError(String message, String? resultCode) {
    final communicationErrors = [
      'API_CONNECT_FAIL_SERVER',
      'API_CONNECT_FAIL_TERMINAL',
      'API_CONNECTION_LOST_SERVER',
      'API_CONNECTION_LOST_TERMINAL',
    ];

    if (resultCode != null) {
      return communicationErrors.contains(resultCode);
    }
    return communicationErrors.any((error) => message.contains(error));
  }

  bool _isRequestError(String message, String? resultCode) {
    final requestErrors = [
      'REQUEST_PENDING',
    ];

    if (resultCode != null) {
      return requestErrors.contains(resultCode);
    }
    return requestErrors.any((error) => message.contains(error));
  }

  Future<void> getTerminalStatus() async {
    await _requestCurrentStatus();
  }

Future<void> _requestCurrentStatus() async {
    try {

      final status = await FlutterSpi.getTerminalStatus();
      print("🔍 Current terminal status: $status");
      _updateStatusFromTerminalResponse(status);
      
    } catch (e) {
      print("❌ Failed to request current status: $e");
      _updatePairingFlowStatus(ANZPairingFlowStatus.idle);
      _updateConnectionStatus(ANZConnectionStatus.disconnected);
    }
  }

  void _updateStatusFromTerminalResponse(String statusString) {
    // 从状态字符串中提取 connectionStatus
    // 示例: "transactionStatus=IDLE, connectionStatus=DISCONNECTED, managementStatus=CLOSED, ..."
    
    String? connectionStatus;
    
    // 查找 connectionStatus 的值
    final connectionStatusMatch = RegExp(r'connectionStatus=([^,\s]+)').firstMatch(statusString);
    if (connectionStatusMatch != null) {
      connectionStatus = connectionStatusMatch.group(1);
    }

    switch (connectionStatus?.toUpperCase()) {
      case 'LOGGED_IN':
        _updateConnectionStatus(ANZConnectionStatus.loggedIn);
        break;
      case 'LOGGED_OUT':
        _updateConnectionStatus(ANZConnectionStatus.loggedOut);
        break;
      case 'DISCONNECTED':
      default:
        _updateConnectionStatus(ANZConnectionStatus.disconnected);
        break;
    }
  }

  void _resetStatusForCommunicationError([String? errorMessage]) {
    _updatePairingFlowStatus(ANZPairingFlowStatus.failed);
    _updateConnectionStatus(ANZConnectionStatus.disconnected);
    _updateTransactionStatus(ANZTransactionStatus.idle); //TODO: check later
    _updateUnpairStatus(ANZUnpairStatus.idle);
    _lastTransaction = null;
    _isBalanceInProgress = false;

    final displayMessage = errorMessage != null && errorMessage.isNotEmpty
        ? "连接错误: $errorMessage"
        : "连接已断开，请重新连接";
    
    EasyLoading.showToast(
      displayMessage,
      duration: Duration(seconds: 3),
    );

    _requestCurrentStatus();
    
    notifyListeners();
  }

  // Helper methods for UI
  String getStatusText(dynamic status) {
    switch (status) {
      case ANZPairingFlowStatus.idle:
        return "Idle";
      case ANZPairingFlowStatus.connecting:
        return "Connecting";
      case ANZPairingFlowStatus.loggingIn:
        return "Logging In";
      case ANZPairingFlowStatus.activating:
        return "Activating";
      case ANZPairingFlowStatus.failed:
        return "Failed";
      case ANZPairingFlowStatus.connected:
        return "Connected";
      case ANZPairingFlowStatus.loggedIn:
        return "Logged In";
      case ANZPairingFlowStatus.activated:
        return "Activated";
      case ANZUnpairStatus.failed:
        return "Unpair Failed";
      case ANZUnpairStatus.idle:
        return "";
      case ANZTransactionStatus.idle:
        return "Idle";
      case ANZTransactionStatus.processing:
        return "Processing...";
      case ANZTransactionStatus.completed:
        return "Completed";
      case ANZTransactionStatus.failed:
        return "Failed";
      case ANZConnectionStatus.disconnected:
        return "Disconnected";
      case ANZConnectionStatus.loggedIn:
        return "Logged In";
      case ANZConnectionStatus.loggedOut:
        return "Logged Out";
      case ANZUnpairStatus.disposed:
        return "Disposed";
      default:
        return "Unknown";
    }
  }

  Color getStatusColor(dynamic status) {
    switch (status) {
      case ANZPairingFlowStatus.idle:
        return Colors.grey;
      case ANZPairingFlowStatus.connecting:
      case ANZPairingFlowStatus.loggingIn:
      case ANZPairingFlowStatus.activating:
        return Colors.orange;
      case ANZPairingFlowStatus.failed:
        return Colors.red;
      case ANZUnpairStatus.failed:
        return Colors.red;
      case ANZPairingFlowStatus.connected:
      case ANZPairingFlowStatus.loggedIn:
        return Colors.blue;
      case ANZPairingFlowStatus.activated:
      case ANZUnpairStatus.disposed:
        return Colors.green;
      case ANZConnectionStatus.disconnected:
        return Colors.red;
      case ANZConnectionStatus.loggedIn:
        return Colors.green;
      case ANZConnectionStatus.loggedOut:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color getTransactionStatusColor() {
    switch (_transactionStatus) {
      case ANZTransactionStatus.idle:
        return Colors.grey;
      case ANZTransactionStatus.processing:
        return Colors.orange;
      case ANZTransactionStatus.completed:
        return Colors.green;
      case ANZTransactionStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 检查终端是否准备好处理交易
  bool get isReady => _pairingFlowStatus == ANZPairingFlowStatus.activated;
  
  // 检查是否有交易正在进行中
  bool get isTransactionInProgress => _transactionStatus == ANZTransactionStatus.processing;
  
  // 检查是否有交易数据
  bool get hasTransactionData => _lastTransaction != null;
  
  // 检查是否正在等待配对结果
  bool get isWaitingForPairingResult {
    // 如果配对成功、失败或空闲，不在等待
    if (_pairingFlowStatus == ANZPairingFlowStatus.activated || 
        _pairingFlowStatus == ANZPairingFlowStatus.failed ||
        _pairingFlowStatus == ANZPairingFlowStatus.idle) {
      return false;
    }
    
    // 其他情况都在等待配对结果
    return true;
  }
  
  // 保持向后兼容
  bool get isWaitingForConnectionResult => isWaitingForPairingResult;

  String getCurrentLoadingStatus() {
    switch (_pairingFlowStatus) {
      case ANZPairingFlowStatus.connecting:
        return "Connecting...";
      case ANZPairingFlowStatus.loggingIn:
        return "Logging in...";
      case ANZPairingFlowStatus.activating:
        return "Activating...";
      default:
        return "";
    }
  }

  @override
  void dispose() {
    _pairingTimeoutTimer?.cancel();
    _eventSubscription?.cancel();
    _eventsSubscribed = false;
    super.dispose();
  }
}