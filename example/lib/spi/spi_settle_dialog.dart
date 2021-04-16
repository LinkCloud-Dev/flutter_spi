import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spi_example/spi_model.dart';

class SettleDialog extends StatelessWidget {
  SettleDialog({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);

    return SimpleDialog(
      contentPadding: EdgeInsets.all(0),
      titlePadding: EdgeInsets.fromLTRB(40, 0, 40, 0),
      title: Text('EFTPOS - Settle'),
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              Text(spi.transactionFlowState.displayMessage),
              spi.transactionFlowState.finished
                  ? ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    )
                  : SizedBox.shrink()
            ],
          ),
        ),
      ],
    );
  }
}
