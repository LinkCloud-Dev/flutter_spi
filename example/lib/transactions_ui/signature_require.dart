import 'package:flutter/material.dart';
import 'package:flutter_spi/flutter_spi.dart';

class SignatureRequire extends StatelessWidget {
  final int amount;
  const SignatureRequire({Key key, @required this.amount}) : super(key: key);

  Future<void> _acceptSignature(bool accepted) async {
    await FlutterSpi.acceptSignature(accepted);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text('Please ask customer to sign receipt'),
          Text('\$${(amount / 100).toStringAsFixed(2)}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  onPressed: () => _acceptSignature(false),
                  child: Text('Decline Sig.')),
              ElevatedButton(
                  onPressed: () => _acceptSignature(true),
                  child: Text('Accept Sig.')),
            ],
          )
        ],
      ),
    );
  }
}
