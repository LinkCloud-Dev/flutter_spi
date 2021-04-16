import 'package:flutter/material.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'dart:async';

import 'package:flutter_spi_example/spi_model.dart';
import 'package:flutter_spi_example/spi_transaction_dialog.dart';
import 'package:provider/provider.dart';

class Transaction extends StatelessWidget {
  const Transaction({Key key}) : super(key: key);

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

  Future<void> _showDialog<T>({BuildContext context, Widget child}) async {
    await showDialog<T>(
      context: context,
      builder: (context) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purcharse'),
      ),
      body: Container(
        padding: EdgeInsets.all(30),
        child: Center(
          child: ElevatedButton(
              onPressed: () => _startTransaction(100, context),
              child: Text('Charge \$1.00')),
        ),
      ),
    );
  }
}
