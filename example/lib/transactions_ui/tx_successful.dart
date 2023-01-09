import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../spi_model.dart';

class TxSuccessful extends StatelessWidget {
  final int amount;
  const TxSuccessful({Key? key, required this.amount}) : super(key: key);

  void _ok(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: false);
    spi.resetTransaction();
    Navigator.pop(context);
  }

  Future<void> _printCustomerCopy(String customerCopy) async {
    // TODO: print customer copy
    print(customerCopy);
  }

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);
    String? responseText;
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
          Text('Transaction Successful'),
          responseText != null && responseText.isNotEmpty
              ? Text('EFTPOS: $responseText')
              : SizedBox.shrink(),
          Text('\$${(amount / 100).toStringAsFixed(2)}'),
          customerCopy != null && customerCopy.isNotEmpty
              ? ElevatedButton(
                  onPressed: () => _printCustomerCopy(customerCopy!),
                  child: Text('PRINT CUSTOMER COPY'))
              : SizedBox.shrink(),
          ElevatedButton(
            onPressed: () => _ok(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
