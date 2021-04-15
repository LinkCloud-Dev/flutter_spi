import 'package:flutter/material.dart';
import 'package:flutter_spi/flutter_spi.dart';

class WaitingTx extends StatelessWidget {
  final int amount;
  const WaitingTx({Key key, @required this.amount}) : super(key: key);

  Future<void> _cancelTx() async {
    await FlutterSpi.cancelTransaction();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text('Asking EFTPOS to accept payment for'),
          Text('\$${(amount / 100).toStringAsFixed(2)}'),
          ElevatedButton(onPressed: _cancelTx, child: Text('CANCEL'))
        ],
      ),
    );
  }
}
