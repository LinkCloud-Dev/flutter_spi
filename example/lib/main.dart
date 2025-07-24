import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi_example/spi/spi_refund_dialog.dart';
import 'package:flutter_spi_example/spi/spi_settle_dialog.dart';
import 'package:flutter_spi_example/spi/spi_transaction_dialog.dart';
import 'package:flutter_spi_example/spi_model.dart';
import 'package:flutter_spi_example/spi_pair.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'anz_connect_UI.dart';
import 'anz_state.dart';
import 'charge_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpiModel()),
        ChangeNotifierProvider(create: (_) => AnzState()),
      ],
      child: MaterialApp(
        title: 'Spi Demo',
        initialRoute: '/',
        routes: {
          '/': (context) => const Home(),
          '/pair': (context) => const Pair(),
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<String> _lastReceipts = [];
  bool _canPrint = false;

  @override
  void initState() {
    super.initState();
    _initSpi();
  }

  void _initSpi() async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    await spi.init();
    FlutterSpi.handleMethodCall(spi.subscribeSpiEvents);
    await FlutterSpi.start();
    final anzState = Provider.of<AnzState>(context, listen: false);
    anzState.init();
  }

  Future<void> _startTransaction(int amount, BuildContext context) async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    if (spi.status == SpiStatus.UNPAIRED) {
      print('Please Pair EFTPOS.');
      return;
    }
    await spi.initiatePurchaseTx(const Uuid().v4(), amount, 0, 0, false);
    _showDialog<String>(
      context: context,
      child: TransactionDialog(
        amount: amount,
      ),
    );
  }

  Future<void> _initSettleTx(BuildContext context) async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    if (spi.status == SpiStatus.UNPAIRED) {
      print('Please Pair EFTPOS.');
      return;
    }
    await FlutterSpi.initiateSettleTx(const Uuid().v4());
    _showDialog<String>(
      context: context,
      child: SettleDialog(),
    );
  }

  Future<void> _initRefundTx(int amount, BuildContext context) async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    if (spi.status == SpiStatus.UNPAIRED) {
      print('Please Pair EFTPOS.');
      return;
    }
    await FlutterSpi.initiateRefundTx(const Uuid().v4(), amount);
    _showDialog<String>(
      context: context,
      child: RefundTransactionDialog(
        amount: amount,
      ),
    );
  }

  void _endTx(BuildContext context) {
    FlutterSpi.ackFlowEndedAndBackToIdle();
  }

  void _getTenants(BuildContext context) async {
    final tenants = await FlutterSpi.getTenantsList("BurgerPosDeviceAPIKey");
    for (Tenant tenant in tenants) {
      print("name: ${tenant.name}, code: ${tenant.code}");
    }
  }

  void _test(BuildContext context) async {
    await FlutterSpi.test();
  }

  Future<void> _showDialog<T>(
      {required BuildContext context, required Widget child}) async {
    await showDialog<T>(
      barrierDismissible: false,
      context: context,
      builder: (context) => child,
    );
  }

  void _timApiPairing(BuildContext context) async {
    // For credentialing - disable printing by default
    await FlutterSpi.timApiPairing(enablePrinting: false);
  }

  void _timApiCharge(BuildContext context) async {
    print('.........dart --- tim api charge');
    
    // 显示交易对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const ChargeDialog();
      },
    );
    
    // 开始交易
    final anzState = Provider.of<AnzState>(context, listen: false);
    await anzState.startTransaction(
      'charge_${DateTime.now().millisecondsSinceEpoch}',
      1500,
    );
  }

  void _timApiRefund(BuildContext context) async {
    await FlutterSpi.timApiRefund(1500);
  }

  void _timApiRefRefund(BuildContext context) async {
    await FlutterSpi.timApiRefRefund();
  }

  void _timApiBalance(BuildContext context) async {
    await FlutterSpi.timApiBalance();
  }

  void _timApiReversal(BuildContext context) async {
    final anzState = Provider.of<AnzState>(context, listen: false);
    await anzState.startReversal();
  }

  /*void _timApiPrint(String ticket) async {
    await FlutterSpi.timApiPrint(ticket);
  }*/

  @override
  Widget build(BuildContext context) {
    var anzState = Provider.of<AnzState>(context);
    var spi = Provider.of<SpiModel>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spi Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            (spi.status == SpiStatus.UNPAIRED && spi.secrets != null)
                ? Container(
                    margin: const EdgeInsets.all(15),
                    child: const Text('STATUS: DISCONNECTED'),
                  )
                : Container(
                    margin: const EdgeInsets.all(15),
                    child: Text(
                        'STATUS: ${EnumToString.convertToString(spi.status)}'),
                  ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/pair'),
              child: const Text('Pair'),
            ),
            ElevatedButton(
              onPressed: () => _startTransaction(1500, context),
              child: const Text('Charge \$15.00'),
            ),
            ElevatedButton(
              onPressed: () => _startTransaction(1508, context),
              child: const Text('Charge \$15.08'),
            ),
            ElevatedButton(
              onPressed: () => _initSettleTx(context),
              child: const Text('Settle'),
            ),
            ElevatedButton(
              onPressed: () => _initRefundTx(1500, context),
              child: const Text('Refund \$15.00'),
            ),
            ElevatedButton(
              onPressed: () => _endTx(context),
              child: const Text('End Transaction'),
            ),
            ElevatedButton(
              onPressed: () => _getTenants(context),
              child: Text('Get Tenants'),
            ),
            ElevatedButton(
              onPressed: () => _test(context),
              child: Text('Test'),
            ),
            ElevatedButton(
              onPressed: () => _timApiPairing(context),
              child: const Text('Init (TIM API)'),
            ),
            
            // ANZ Terminal section
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'ANZ Terminal Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: anzState.getStatusColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${anzState.getStatusText()}',
                    style: TextStyle(
                      fontSize: 16,
                      color: anzState.getStatusColor(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _timApiPairing(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text(
                            'Init',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const AnzConnectUI(),
                            );
                            await anzState.startConnection();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: anzState.isReady ? Colors.green : Colors.orange,
                          ),
                          child: Text(
                            anzState.isReady ? 'Ready' : 'Connect',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                 
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _timApiCharge(context),
              child: const Text('Charge (TIM API)'),
            ),
            ElevatedButton(
              onPressed: () => _timApiRefund(context),
              child: const Text('Standard Refund (TIM API)'),
            ),
            ElevatedButton(
              onPressed: () => _timApiRefRefund(context),
              child: const Text('Reference Refund (TIM API)'),
            ),
            ElevatedButton(
              onPressed: () => _timApiBalance(context),
              child: const Text('Balance (TIM API)'),
            ),
            ElevatedButton(
              onPressed: () => _timApiReversal(context),
              child: const Text('Reversal (TIM API)'),
            ),
            /*ElevatedButton( // Function disallowed in API
              onPressed: _canPrint
                  ? () {
                for (final ticket in _lastReceipts) {
                   _timApiPrint(ticket);
                }
              }
                  : null,
              child: Text("Print (TIM API)"),
            ),*/
          ],
        ),
      ),
    );
  }
}
