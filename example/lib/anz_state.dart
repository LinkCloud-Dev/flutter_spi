import 'package:flutter/material.dart';
import 'package:flutter_spi/flutter_spi.dart';

enum ANZTerminalStatus {
  disconnected,    // 未连接
  connecting,      // 正在连接
  connected,       // 连接成功，准备登录
  loggingIn,       // 正在登录
  loggedIn,        // 登录成功，准备激活
  activating,      // 正在激活
  activated,       // 激活成功，终端就绪
}

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

class ANZTransactionData {
  final String? posRefId;
  final double? amount;
  final String? currency;
  final String? transactionType;
  final String? transRef;
  final String? transSeq;
  final String? cardRef;
  final String? acqTransRef;
  final List<String>? receipts;
  final String? errorMessage;

  ANZTransactionData({
    this.posRefId,
    this.amount,
    this.currency,
    this.transactionType,
    this.transRef,
    this.transSeq,
    this.cardRef,
    this.acqTransRef,
    this.receipts,
    this.errorMessage,
  });

  factory ANZTransactionData.fromMap(Map<String, dynamic> map) {
    return ANZTransactionData(
      posRefId: map['posRefId']?.toString(),
      amount: map['amount']?.toDouble(),
      currency: map['currency']?.toString(),
      transactionType: map['transactionType']?.toString(),
      transRef: map['transRef']?.toString(),
      transSeq: map['transSeq']?.toString(),
      cardRef: map['cardRef']?.toString(),
      acqTransRef: map['acqTransRef']?.toString(),
      receipts: map['receipts'] != null 
          ? List<String>.from((map['receipts'] as List).map((item) => item.toString()))
          : null,
      errorMessage: map['errorMessage']?.toString(),
    );
  }

  factory ANZTransactionData.error(String errorMessage) {
    return ANZTransactionData(errorMessage: errorMessage);
  }
}

class AnzState extends ChangeNotifier {
  // 我们的流程状态
  ANZTerminalStatus _status = ANZTerminalStatus.disconnected;
  ANZTerminalStatus get status => _status;
  
  // TIM API 的连接状态
  ANZConnectionStatus _connectionStatus = ANZConnectionStatus.disconnected;
  ANZConnectionStatus get connectionStatus => _connectionStatus;
  
  // Transaction 相关状态
  ANZTransactionStatus _transactionStatus = ANZTransactionStatus.idle;
  ANZTransactionStatus get transactionStatus => _transactionStatus;
  
  ANZTransactionData? _lastTransaction;
  ANZTransactionData? get lastTransaction => _lastTransaction;
  
  String? _currentTransactionId;
  String? get currentTransactionId => _currentTransactionId;
  
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _subscribeTimEvents();
  }

  void _updateStatus(ANZTerminalStatus newStatus) {
    _status = newStatus;
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

  Future<void> startConnection() async {
    try {
      _updateStatus(ANZTerminalStatus.connecting);
      await FlutterSpi.timApiConnect();
    } catch (e) {
      print("❌ Connect failed: $e");
      _updateStatus(ANZTerminalStatus.disconnected);
    }
  }

  Future<void> _login() async {
    try {
      _updateStatus(ANZTerminalStatus.loggingIn);
      await FlutterSpi.timApiLogin();
    } catch (e) {
      print("❌ Login failed: $e");
      _updateStatus(ANZTerminalStatus.connected);
    }
  }

  Future<void> _activate() async {
    try {
      _updateStatus(ANZTerminalStatus.activating);
      await FlutterSpi.timApiActivate();
    } catch (e) {
      print("❌ Activate failed: $e");
      _updateStatus(ANZTerminalStatus.loggedIn);
    }
  }

  // Transaction methods
  Future<void> startTransaction(String posRefId, double amount) async {
    if (_status != ANZTerminalStatus.activated) {
      print("❌ Terminal not ready for transaction");
      return;
    }

    // 重置之前的交易状态
    _resetTransactionState();
    
    try {
      _currentTransactionId = posRefId;
      _updateTransactionStatus(ANZTransactionStatus.processing);
      await FlutterSpi.timApiCharge(amount);
    } catch (e) {
      print("❌ Start transaction failed: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      _lastTransaction = ANZTransactionData.error("Failed to start transaction: $e");
    }
  }

  void _resetTransactionState() {
    _updateTransactionStatus(ANZTransactionStatus.idle);
    _lastTransaction = null;
    _currentTransactionId = null;
  }

  Future<void> startRefund(String posRefId, double amount) async {
    if (_status != ANZTerminalStatus.activated) {
      print("❌ Terminal not ready for refund");
      return;
    }

    // 重置之前的交易状态
    _resetTransactionState();

    try {
      _currentTransactionId = posRefId;
      _updateTransactionStatus(ANZTransactionStatus.processing);
      await FlutterSpi.timApiRefund(amount);
    } catch (e) {
      print("❌ Start refund failed: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      _lastTransaction = ANZTransactionData.error("Failed to start refund: $e");
    }
  }

  Future<void> startBalance() async {
    if (_status != ANZTerminalStatus.activated) {
      print("❌ Terminal not ready for balance");
      return;
    }

    // 重置之前的交易状态
    _resetTransactionState();

    try {
      _currentTransactionId = "balance_${DateTime.now().millisecondsSinceEpoch}";
      _updateTransactionStatus(ANZTransactionStatus.processing);
      await FlutterSpi.timApiBalance();
    } catch (e) {
      print("❌ Start balance failed: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      _lastTransaction = ANZTransactionData.error("Failed to start balance: $e");
    }
  }

  Future<void> startReversal() async {
  if (_status != ANZTerminalStatus.activated) {
    print("❌ Terminal not ready for reversal");
    return;
  }
  if (_lastTransaction?.transSeq == null) {
    print("❌ No previous transaction to reverse");
    return;
  }
  try {
    _currentTransactionId = "reversal_${DateTime.now().millisecondsSinceEpoch}";
    _updateTransactionStatus(ANZTransactionStatus.processing);
    await FlutterSpi.timApiReversal(transSeq: _lastTransaction!.transSeq!);
  } catch (e) {
    print("❌ Start reversal failed: $e");
    _updateTransactionStatus(ANZTransactionStatus.failed);
    _lastTransaction = ANZTransactionData.error("Failed to start reversal: $e");
  }
}

  void _subscribeTimEvents() {
    FlutterSpi.eventStream.listen((event) {
      print("🔔 ANZState 收到 TIM API 事件: $event");

      // 确保 event 是 Map 类型
      if (event is! Map) {
        print("⚠️ 收到非 Map 类型事件: $event");
        return;
      }

      final eventMap = Map<String, dynamic>.from(event);
      final eventType = eventMap['type'] as String?;

      switch (eventType) {
        case 'connectCompleted':
          if (eventMap['status'] == 'success') {
            print("✅ Connect completed, calling login");
            _updateStatus(ANZTerminalStatus.connected);
            _login();
          } else {
            print("❌ Connect failed");
            _updateStatus(ANZTerminalStatus.disconnected);
          }
          break;
        case 'loginCompleted':
          if (eventMap['status'] == 'success') {
            print("✅ Login completed, calling activate");
            _updateStatus(ANZTerminalStatus.loggedIn);
            _activate();
          } else {
            print("❌ Login failed");
            _updateStatus(ANZTerminalStatus.connected);
          }
          break;
        case 'activateCompleted':
          if (eventMap['status'] == 'success') {
            print("✅ Activate completed, terminal is ready");
            _updateStatus(ANZTerminalStatus.activated);
          } else {
            print("❌ Activate failed");
            _updateStatus(ANZTerminalStatus.loggedIn);
          }
          break;
        case 'terminalStatusChanged':
          _handleTerminalStatusChanged(eventMap);
          break;
        case 'disconnected':
          _handleDisconnected(eventMap);
          break;
        case 'transactionCompleted':
          _handleTransactionCompleted(eventMap);
          break;
        case 'balanceCompleted':
          _handleBalanceCompleted(eventMap);
          break;
        case 'error':
          _handleError(eventMap);
          break;
        default:
          print("⚠️ 未处理事件类型: $eventType");
      }
    });
  }

  void _handleTerminalStatusChanged(Map<String, dynamic> event) {
    final connectionStatus = event['connectionStatus'] as String?;
    
    print("📊 TIM API ConnectionStatus: $connectionStatus");
    
    // 更新 TIM API 连接状态
    if (connectionStatus != null) {
      switch (connectionStatus) {
        case 'DISCONNECTED':
          _updateConnectionStatus(ANZConnectionStatus.disconnected);
          break;
        case 'LOGGED_IN':
          _updateConnectionStatus(ANZConnectionStatus.loggedIn);
          break;
        case 'LOGGED_OUT':
          _updateConnectionStatus(ANZConnectionStatus.loggedOut);
          break;
        default:
          print("⚠️ Unknown TIM API connection status: $connectionStatus");
      }
    }
  }

  void _handleDisconnected(Map<String, dynamic> event) {
    final errorMessage = event['errorMessage'] as String?;
    final localizedMessage = event['localizedMessage'] as String?;
    
    print("❌ Terminal disconnected:");
    print("  - Error: $errorMessage");
    print("  - Message: $localizedMessage");
    
    // 重置所有状态
    _updateStatus(ANZTerminalStatus.disconnected);
    _updateConnectionStatus(ANZConnectionStatus.disconnected);
    _updateTransactionStatus(ANZTransactionStatus.idle);
    _currentTransactionId = null;
  }

  void _handleTransactionCompleted(Map<String, dynamic> event) {
    print("✅ Transaction completed: $event");
    
    try {
      // 添加详细的调试信息
      print("🔍 Parsing transaction data:");
      print("  - posRefId: ${event['posRefId']} (${event['posRefId']?.runtimeType})");
      print("  - amount: ${event['amount']} (${event['amount']?.runtimeType})");
      print("  - currency: ${event['currency']} (${event['currency']?.runtimeType})");
      print("  - transactionType: ${event['transactionType']} (${event['transactionType']?.runtimeType})");
      print("  - transRef: ${event['transRef']} (${event['transRef']?.runtimeType})");
      print("  - transSeq: ${event['transSeq']} (${event['transSeq']?.runtimeType})");
      print("  - cardRef: ${event['cardRef']} (${event['cardRef']?.runtimeType})");
      print("  - acqTransRef: ${event['acqTransRef']} (${event['acqTransRef']?.runtimeType})");
      print("  - receipts: ${event['receipts']} (${event['receipts']?.runtimeType})");
      
      _lastTransaction = ANZTransactionData.fromMap(event);
      _updateTransactionStatus(ANZTransactionStatus.completed);
      _currentTransactionId = null;
    } catch (e) {
      print("❌ Error parsing transaction data: $e");
      print("❌ Stack trace: ${StackTrace.current}");
      _lastTransaction = ANZTransactionData.error("Error parsing transaction data: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
    }
  }

  void _handleBalanceCompleted(Map<String, dynamic> event) {
    print("✅ Balance completed: $event");
    
    try {
      _lastTransaction = ANZTransactionData.fromMap({
        ...event,
        'transactionType': 'BALANCE',
        'posRefId': _currentTransactionId,
      });
      _updateTransactionStatus(ANZTransactionStatus.completed);
      _currentTransactionId = null;
    } catch (e) {
      print("❌ Error parsing balance data: $e");
      _lastTransaction = ANZTransactionData.error("Error parsing balance data: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
    }
  }

  void _handleError(Map<String, dynamic> event) {
    final message = event['message'] as String? ?? "Unknown error";
    print("❌ TIM API 错误: $message");
    
    _lastTransaction = ANZTransactionData.error(message);
    _updateTransactionStatus(ANZTransactionStatus.failed);
    _currentTransactionId = null;
  }

  // Helper methods for UI
  String getStatusText() {
    switch (_status) {
      case ANZTerminalStatus.disconnected:
        return "Disconnected";
      case ANZTerminalStatus.connecting:
        return "Connecting...";
      case ANZTerminalStatus.connected:
        return "Connected";
      case ANZTerminalStatus.loggingIn:
        return "Logging In...";
      case ANZTerminalStatus.loggedIn:
        return "Logged In";
      case ANZTerminalStatus.activating:
        return "Activating...";
      case ANZTerminalStatus.activated:
        return "Activated";
    }
  }

  String getConnectionStatusText() {
    switch (_connectionStatus) {
      case ANZConnectionStatus.disconnected:
        return "TIM: Disconnected";
      case ANZConnectionStatus.loggedIn:
        return "TIM: Logged In";
      case ANZConnectionStatus.loggedOut:
        return "TIM: Logged Out";
    }
  }

  String getTransactionStatusText() {
    switch (_transactionStatus) {
      case ANZTransactionStatus.idle:
        return "Idle";
      case ANZTransactionStatus.processing:
        return "Processing...";
      case ANZTransactionStatus.completed:
        return "Completed";
      case ANZTransactionStatus.failed:
        return "Failed";
    }
  }

  Color getStatusColor() {
    switch (_status) {
      case ANZTerminalStatus.disconnected:
        return Colors.red;
      case ANZTerminalStatus.connecting:
      case ANZTerminalStatus.loggingIn:
      case ANZTerminalStatus.activating:
        return Colors.orange;
      case ANZTerminalStatus.connected:
      case ANZTerminalStatus.loggedIn:
        return Colors.blue;
      case ANZTerminalStatus.activated:
        return Colors.green;
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
    }
  }

  bool get isReady => _status == ANZTerminalStatus.activated;
  bool get isTransactionInProgress => _transactionStatus == ANZTransactionStatus.processing;
  bool get hasTransactionData => _lastTransaction != null;
}