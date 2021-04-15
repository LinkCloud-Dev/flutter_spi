import 'dart:html';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../spi_model.dart';

class TxUnknown extends StatelessWidget {
  final int amount;
  const TxUnknown({Key key, @required this.amount}) : super(key: key);

  void _cancel(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: false);
    spi.resetTransaction();
    // TOTO: process businiess logic
  }

  Future<void> _retry(BuildContext context) async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    await spi.retryTransaction('111122223333', 100, 0, 0, false);
  }

  Future<void> _overrideAsPaid(BuildContext context) async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    spi.resetTransaction();
    // TODO: process business logic
  }

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);
    String responseText;
    if (spi.transactionFlowState.response.data['host_response_text'] != null) {
      responseText =
          spi.transactionFlowState.response.data['host_response_text'];
    }

    String customerCopy;
    if (spi.transactionFlowState.response.data['customer_receipt'] != null) {
      customerCopy = spi.transactionFlowState.response.data['customer_receipt'];
    }

    return Container(
      child: Column(
        children: [
          Text('Transaction Unknown'),
          Text('\$${(amount / 100).toStringAsFixed(2)}'),
          Text('Check whether customer actually paid.'),
          Text('What would you link to do next?'),
          ElevatedButton(
              onPressed: () => _retry(context),
              child: Text('Retry Transaction')),
          ElevatedButton(
              onPressed: () => _overrideAsPaid(context),
              child: Text('Override as Paid')),
          ElevatedButton(
              onPressed: () => _cancel(context), child: Text('Canncel')),
        ],
      ),
    );
  }
}
