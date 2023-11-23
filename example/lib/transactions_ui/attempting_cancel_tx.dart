import 'package:flutter/material.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi_example/spi_model.dart';

class WaitingConnection extends StatelessWidget {
  final int amount;
  const WaitingConnection({Key? key, required this.amount}) : super(key: key);

  Future<void> _cancelTx() async {
    await FlutterSpi.cancelTransaction();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          const Text('Waiting for EFTPOS Connection'),
          Text('\$${(amount / 100).toStringAsFixed(2)}'),
          ElevatedButton(onPressed: _cancelTx, child: Text('CANCEL'))
        ],
      ),
    );
  }
}
