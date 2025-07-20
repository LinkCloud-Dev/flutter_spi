import 'package:flutter/material.dart';
import 'package:flutter_spi/flutter_spi.dart';

enum ANZTerminalStatus {
  disconnected,    // 未连接
  connecting,      // 正在连接
  connected,       // 连接成功，准备登录
  loggingIn,       // 正在登录
  loggedIn,        // 登录成功，准备激活
  activating,      // 正在激活
  activated,           // 激活成功，终端就绪
}

enum ANZConnectionStatus {
  disconnected,    // TIM API: DISCONNECTED
  loggedIn,        // TIM API: LOGGED_IN
  loggedOut,       // TIM API: LOGGED_OUT
}

class AnzState extends ChangeNotifier {
  // 我们的流程状态
  ANZTerminalStatus _status = ANZTerminalStatus.disconnected;
  ANZTerminalStatus get status => _status;
  
  // TIM API 的连接状态
  ANZConnectionStatus _connectionStatus = ANZConnectionStatus.disconnected;
  ANZConnectionStatus get connectionStatus => _connectionStatus;
  
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
          print("✅ Transaction completed.");
          break;
        case 'error':
          print("❌ TIM API 错误: ${eventMap['message']}");
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
    
    // 重置两个状态
    _updateStatus(ANZTerminalStatus.disconnected);
    _updateConnectionStatus(ANZConnectionStatus.disconnected);
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

  bool get isReady => _status == ANZTerminalStatus.activated;
}