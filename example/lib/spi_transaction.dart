import 'package:flutter/material.dart';
import 'package:flutter_spi_example/spi_model.dart';
import 'package:provider/provider.dart';

enum TxUiState {
  WaitingTx,
  WaitingConnection,
  SignatureRequire,
  AttemptingCancelTransaction,
  TxFailed,
  TxSuccess,
  UnknownTx,
}

class TransactionDialog extends StatelessWidget {
  TransactionDialog({
    Key key,
  }) : super(key: key);

  void _cancel(BuildContext context) async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    await spi.cancelPair();
  }

  void _confirmPairingCode(BuildContext context) async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    await spi.confirmPairingCode();
  }

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);
    return SimpleDialog(
      contentPadding: EdgeInsets.all(0),
      titlePadding: EdgeInsets.fromLTRB(40, 0, 40, 0),
      title: Text('EFTPOS - Order XYZ'),
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              !spi.pairingFlowState.awaitingCheckFromEftpos &&
                      !spi.pairingFlowState.awaitingCheckFromPos &&
                      spi.pairingFlowState.message.isNotEmpty &&
                      !spi.pairingFlowState.finished
                  ? Column(
                      children: [
                        Text(spi.pairingFlowState.message),
                        ElevatedButton(
                            onPressed: () => _cancel(context),
                            child: Text('CANCEL'))
                      ],
                    )
                  : SizedBox.shrink(),
              spi.pairingFlowState.awaitingCheckFromEftpos &&
                      spi.pairingFlowState.confirmationCode.isNotEmpty &&
                      !spi.pairingFlowState.finished
                  ? Column(
                      children: [
                        Text('MATCH THE FOLLOWING CODE WITH THE EFTPOS'),
                        Text(spi.pairingFlowState.confirmationCode),
                        Text('DOES CODE MATCH?'),
                        Row(
                          children: [
                            ElevatedButton(
                                onPressed: () => _cancel(context),
                                child: Text('NO, IT DOES NOT')),
                            ElevatedButton(
                                onPressed: () => _confirmPairingCode(context),
                                child: Text('YES IT MEATCHES'))
                          ],
                        )
                      ],
                    )
                  : SizedBox.shrink(),
              spi.pairingFlowState.awaitingCheckFromEftpos &&
                      !spi.pairingFlowState.awaitingCheckFromPos &&
                      spi.pairingFlowState.confirmationCode.isNotEmpty &&
                      !spi.pairingFlowState.finished
                  ? Column(
                      children: [
                        Text('MATCH THE FOLLOWING CODE WITH THE EFTPOS'),
                        Text(spi.pairingFlowState.confirmationCode),
                        Text('ALSO CONFIRM ON THE EFTPOS ITSELF'),
                        ElevatedButton(
                            onPressed: () => _cancel(context),
                            child: Text('CANCEL'))
                      ],
                    )
                  : SizedBox.shrink(),
              spi.pairingFlowState.finished
                  ? Column(
                      children: [
                        Text(spi.pairingFlowState.message),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'))
                      ],
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}
