import 'package:flutter/material.dart';

class AttemptingCancelTransaction extends StatelessWidget {
  final int amount;
  const AttemptingCancelTransaction({Key? key, required this.amount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text('Attempting to Cancel Transaction...'),
          Text('\$${(amount / 100).toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
