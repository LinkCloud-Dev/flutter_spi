import 'package:flutter/material.dart';
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

enum ANZPairStatus {
  disconnected, // 未连接
  connected,    // 物理/网络已连，未登录
  loggedIn,     // 已登录
  activated,    // 终端就绪
}

enum ANZUnpairStatus {
  idle,            // 未解绑
  disposed,        // dispose完成
  failed,          // 解绑失败
}

class AnzState extends ChangeNotifier {

  
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

  ANZPairStatus _pairStatus = ANZPairStatus.disconnected;
  ANZPairStatus get pairStatus => _pairStatus;

  ANZUnpairStatus _unpairStatus = ANZUnpairStatus.idle;
  ANZUnpairStatus get unpairStatus => _unpairStatus;
  
  // 添加标志来跟踪是否正在进行 balance 操作
  bool _isBalanceInProgress = false;
  bool get isBalanceInProgress => _isBalanceInProgress;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _subscribeTimEvents();
  }

  void initWhenNeeded() {
    if (!_initialized) {
      init();
    }
  }

  // void syncWithSpiStatus(SpiStatus? spiStatus) {
  //   if (spiStatus == null) {
  //     _updatePairStatus(ANZPairStatus.disconnected);
  //     return;
  //   }
  //
  //   switch (spiStatus) {
  //     case SpiStatus.UNPAIRED:
  //     // UNPAIRED state always corresponds to disconnected
  //       _updatePairStatus(ANZPairStatus.disconnected);
  //       _updateUnpairStatus(ANZUnpairStatus.idle);
  //       break;
  //     case SpiStatus.PAIRED_CONNECTING:
  //       _updatePairStatus(ANZPairStatus.connecting);
  //       _updateUnpairStatus(ANZUnpairStatus.idle);
  //       break;
  //     case SpiStatus.PAIRED_CONNECTED:
  //     // If SPI is connected, but ANZ hasn't completed the activation process, stay in the current state
  //       if (_pairStatus == ANZPairStatus.disconnected) {
  //         _updatePairStatus(ANZPairStatus.connected);
  //         _updateUnpairStatus(ANZUnpairStatus.idle);
  //       }
  //       break;
  //   }
  // }

  void _updatePairStatus(ANZPairStatus newStatus) {
    _pairStatus = newStatus;
    notifyListeners();
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

  Future<void> startConnection() async {
    try {
      await FlutterSpi.timApiConnect();
    } catch (e) {
      print("❌ Connect failed: $e");
      _updatePairStatus(ANZPairStatus.disconnected);
      // 将错误信息保存到 transaction data 中，以便在UI中显示
      _lastTransaction = ANZTransactionData.error("Connection failed: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      notifyListeners();
    }
  }

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
    _currentTransactionId = null;
  }
  
  void clearError() {
    _lastTransaction = null;
    _updateTransactionStatus(ANZTransactionStatus.idle);
    notifyListeners();
  }
  // Transaction methods
  Future<void> startTransaction(String posRefId, double amount) async {
    if (_pairStatus != ANZPairStatus.activated) { //TODO: check later
      print("❌ Terminal not ready for transaction");
      return;
    }
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

  Future<void> startRefund(String posRefId, double amount) async {
    if (_pairStatus != ANZPairStatus.activated) {
      print("❌ Terminal not ready for refund");
      return;
    }

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

  Future<void> startReferenceRefund(
    String posRefId, 
    double amount, 
    String sixTrxRefNum,
  ) async {
    if (_pairStatus != ANZPairStatus.activated) {
      print("❌ Terminal not ready for reference refund");
      return;
    }

    _resetTransactionState();

    try {
      _currentTransactionId = posRefId;
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
    if (_pairStatus != ANZPairStatus.activated) {
      print("❌ Terminal not ready for balance");
      return;
    }

    _resetTransactionState();

    try {
      _currentTransactionId = "balance_${DateTime.now().millisecondsSinceEpoch}";
      _updateTransactionStatus(ANZTransactionStatus.processing);
      _isBalanceInProgress = true;
      await FlutterSpi.timApiBalance();
      _updatePairStatus(ANZPairStatus.disconnected);
    } catch (e) {
      print("❌ Start balance failed: $e");
      _updateTransactionStatus(ANZTransactionStatus.failed);
      _lastTransaction = ANZTransactionData.error("Failed to start balance: $e");
      _isBalanceInProgress = false; 
    }
  }

  Future<void> startReversal() async {
    if (_pairStatus != ANZPairStatus.activated) {
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
          print("✅ Balance completed: $eventMap");
          _isBalanceInProgress = false; 
          print("🔄 Balance operation finished, _isBalanceInProgress = $_isBalanceInProgress");
          break;
        case 'deactivateCompleted':
          if (!_isBalanceInProgress) {
            FlutterSpi.timApiLogout();
          } else {
            print("⏸️ Skipping unpair flow during balance operation");
          }
          break;
        case 'logoutCompleted':
          if (!_isBalanceInProgress) {
            FlutterSpi.timApiDisconnect();
          } else {
            print("⏸️ Skipping unpair flow during balance operation");
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

  void _handleConnectCompleted(Map<String, dynamic> event)async {
    if (event['status'] == 'success') {
      _updatePairStatus(ANZPairStatus.connected);
       await FlutterSpi.timApiLogin();
    } else {
      _updatePairStatus(ANZPairStatus.disconnected);
    }
  }

  void _handleLoginCompleted(Map<String, dynamic> event) async{
    if (event['status'] == 'success') {
      _updatePairStatus(ANZPairStatus.loggedIn);
      await FlutterSpi.timApiActivate();
    } else {
      _updatePairStatus(ANZPairStatus.connected);
    }
  }

  void _handleActivateCompleted(Map<String, dynamic> event) {
    if (event['status'] == 'success') {
      _updatePairStatus(ANZPairStatus.activated);
    } else {
      _updatePairStatus(ANZPairStatus.loggedIn);
    }
  }

  void _handleTerminalStatusChanged(Map<String, dynamic> event) {
    final connectionStatus = event['connectionStatus'] as String?;
    
    print("📊 TIM API ConnectionStatus: $connectionStatus");
    
    if (connectionStatus != null) {
      switch (connectionStatus) {
        case 'DISCONNECTED':
          _updateConnectionStatus(ANZConnectionStatus.disconnected);
          _updatePairStatus(ANZPairStatus.disconnected);
          _updateUnpairStatus(ANZUnpairStatus.idle);
          break;
        case 'LOGGED_IN':
          _updateConnectionStatus(ANZConnectionStatus.loggedIn);
          break;
        case 'LOGGED_OUT':
          _updateConnectionStatus(ANZConnectionStatus.loggedOut);
          _updatePairStatus(ANZPairStatus.disconnected);
          _updateUnpairStatus(ANZUnpairStatus.idle);
          break;
        default:
          print("⚠️ Unknown TIM API connection status: $connectionStatus");
      }
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

  void _handleDisposed(Map<String, dynamic> event) {
      if (event['status'] == 'success') {
        _updateUnpairStatus(ANZUnpairStatus.disposed);
        _updateConnectionStatus(ANZConnectionStatus.disconnected);
        _updatePairStatus(ANZPairStatus.disconnected);
        _currentTransactionId = null;
      } else {
        _updateUnpairStatus(ANZUnpairStatus.failed);
      } 
      notifyListeners();
  }

  void _handleTransactionCompleted(Map<String, dynamic> event) {
    print("✅ Transaction completed: $event");
    
    try {
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

  void _handleError(Map<String, dynamic> event) {
    final message = event['message'] as String? ?? "Unknown error";
    final resultCode = event['resultCode'] as String?;
    print("❌ TIM API 错误: $message (resultCode: $resultCode)");
    
    // 检查是否是通信相关的错误，这些错误可以忽略并自动重置状态
    if (_isCommunicationError(message, resultCode)) {
      print("🔄 检测到通信错误，自动重置状态: $message (resultCode: $resultCode)");
      _resetStatusForCommunicationError();
      return;
    }
    
    _lastTransaction = ANZTransactionData.error(message);
    _updateTransactionStatus(ANZTransactionStatus.failed);
    _currentTransactionId = null;
  }

  bool _isCommunicationError(String message, String? resultCode) {
    final communicationErrors = [
      'API_CONNECT_FAIL_SERVER',
      'API_CONNECT_FAIL_TERMINAL', 
      'API_CONNECTION_LOST_SERVER',
      'API_CONNECTION_LOST_TERMINAL',
    ];
    
    // 优先检查 resultCode，如果存在的话
    if (resultCode != null) {
      return communicationErrors.contains(resultCode);
    }
    
    // 如果没有 resultCode，则检查 message 中是否包含错误信息
    return communicationErrors.any((error) => message.contains(error));
  }

  void _resetStatusForCommunicationError() {
    // 重置所有状态到初始状态
    _updatePairStatus(ANZPairStatus.disconnected);
    _updateConnectionStatus(ANZConnectionStatus.disconnected);
    _updateTransactionStatus(ANZTransactionStatus.idle); //TODO: check later
    _updateUnpairStatus(ANZUnpairStatus.idle);
    _currentTransactionId = null;
    _lastTransaction = null;
    _isBalanceInProgress = false;
    
    // 显示 EasyLoading 提示
    EasyLoading.showToast(
      "连接已断开，请重新连接",
      duration: Duration(seconds: 3),
    );
    
    // 通知UI更新
    notifyListeners();
  }


  // Helper methods for UI
  String getStatusText(dynamic status) {
    switch (status) {
      case ANZPairStatus.disconnected:
        return "Disconnected";
      case ANZPairStatus.connected:
        return "Connected";
      case ANZPairStatus.loggedIn:
        return "Logged In";
      case ANZPairStatus.activated:
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
        return "TIM: Disconnected";
      case ANZConnectionStatus.loggedIn:
        return "TIM: Logged In";
      case ANZConnectionStatus.loggedOut:
        return "TIM: Logged Out";
      case ANZUnpairStatus.disposed:
        return "Disposed";
      default:
        return "Unknown";
    }
  }


  Color getStatusColor(dynamic status) {
    switch (status) {
      case ANZPairStatus.disconnected:
        return Colors.red;
      case ANZUnpairStatus.failed:
        return Colors.orange;
      case ANZPairStatus.connected:
      case ANZPairStatus.loggedIn:
      case ANZPairStatus.activated:
        return Colors.blue; 
      case ANZUnpairStatus.disposed:
        return Colors.green;
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

  bool get isReady => _pairStatus == ANZPairStatus.activated;
  bool get isTransactionInProgress => _transactionStatus == ANZTransactionStatus.processing;
  bool get hasTransactionData => _lastTransaction != null;
}