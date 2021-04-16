import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi_example/spi/spi_refund_dialog.dart';
import 'package:flutter_spi_example/spi/spi_settle_dialog.dart';
import 'package:flutter_spi_example/spi/spi_transaction_dialog.dart';
import 'package:flutter_spi_example/spi_model.dart';
import 'package:flutter_spi_example/spi_pair.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SpiModel(),
      child: MaterialApp(
        title: 'Spi Demo',
        initialRoute: '/',
        routes: {
          '/': (context) => Home(),
          '/pair': (context) => Pair(),
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    _initSpi();
    super.initState();
  }

  void _initSpi() async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    spi.init();
    FlutterSpi.handleMethodCall(spi.subscribeSpiEvents);
  }

  Future<void> _startTransaction(int amount, BuildContext context) async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    if (spi.status == SpiStatus.UNPAIRED) {
      print('Please Pair EFTPOS.');
      return;
    }
    await spi.initiatePurchaseTx('111122223333', 100, 0, 0, false);
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
    await FlutterSpi.initiateSettleTx(Uuid().v4());
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
    await FlutterSpi.initiateRefundTx(Uuid().v4(), amount);
    _showDialog<String>(
      context: context,
      child: RefundTransactionDialog(
        amount: amount,
      ),
    );
  }

  Future<void> _showDialog<T>({BuildContext context, Widget child}) async {
    await showDialog<T>(
      context: context,
      builder: (context) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: Text('Spi Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.all(15),
              child:
                  Text('STATUS: ${EnumToString.convertToString(spi.status)}'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/pair'),
              child: Text('Pair'),
            ),
            ElevatedButton(
              onPressed: () => _startTransaction(100, context),
              child: Text('Charge \$1.00'),
            ),
            ElevatedButton(
              onPressed: () => _initSettleTx(context),
              child: Text('Settle'),
            ),
            ElevatedButton(
              onPressed: () => _initRefundTx(100, context),
              child: Text('Refund \$1.00'),
            ),
          ],
        ),
      ),
    );
  }
}
