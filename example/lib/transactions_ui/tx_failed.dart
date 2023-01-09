import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../spi_model.dart';

class TxFaild extends StatelessWidget {
  final int amount;
  final Function retry;
  const TxFaild({Key? key, required this.amount, required this.retry})
      : super(key: key);

  void _cancel(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: false);
    spi.resetTransaction();
    Navigator.pop(context);
    // TOTO: process businiess logic
  }

  Future<void> _printCustomerCopy(String customerCopy) async {
    // TODO: print customer copy
    print(customerCopy);
  }

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);
    String? responseText;
    if (spi.transactionFlowState!.response!.data!['error_detail'] != null) {
      responseText = spi.transactionFlowState!.response!.data!['error_detail'];
    }
    if (spi.transactionFlowState!.response!.data!['host_response_text'] != null) {
      responseText =
          spi.transactionFlowState!.response!.data!['host_response_text'];
    }

    String? customerCopy;
    if (spi.transactionFlowState!.response!.data!['customer_receipt'] != null) {
      customerCopy = spi.transactionFlowState!.response!.data!['customer_receipt'];
    }

    return Container(
      child: Column(
        children: [
          Text('Transaction Failed'),
          responseText != null && responseText.isNotEmpty
              ? Text('EFTPOS: $responseText')
              : SizedBox.shrink(),
          Text('\$${(amount / 100).toStringAsFixed(2)}'),
          customerCopy != null && customerCopy.isNotEmpty
              ? ElevatedButton(
                  onPressed: () => _printCustomerCopy(customerCopy!),
                  child: Text('PRINT CUSTOMER COPY'))
              : SizedBox.shrink(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  onPressed: () => _cancel(context), child: Text('CLOSE')),
              ElevatedButton(
                  onPressed: () => retry(context), child: Text('RETRY')),
            ],
          )
        ],
      ),
    );
  }
}
