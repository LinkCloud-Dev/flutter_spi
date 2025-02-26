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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SpiModel(),
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
  @override
  void initState() {
    _initSpi();
    super.initState();
  }

  void _initSpi() async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    await spi.init();
    FlutterSpi.handleMethodCall(spi.subscribeSpiEvents);
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

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}
