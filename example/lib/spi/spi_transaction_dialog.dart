import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi_example/spi_model.dart';
import 'package:flutter_spi_example/transactions_ui/attempting_cancel_tx.dart';
import 'package:flutter_spi_example/transactions_ui/signature_require.dart';
import 'package:flutter_spi_example/transactions_ui/tx_failed.dart';
import 'package:flutter_spi_example/transactions_ui/tx_successful.dart';
import 'package:flutter_spi_example/transactions_ui/tx_unknown.dart';
import 'package:flutter_spi_example/transactions_ui/waiting_conn.dart';
import 'package:flutter_spi_example/transactions_ui/waiting_tx.dart';

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
  final int amount;
  TransactionDialog({
    Key key,
    @required this.amount,
  }) : super(key: key);

  Future<void> _retry(BuildContext context) async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    await spi.retryTransaction('111122223333', 100, 0, 0, false);
  }

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);

    Widget content = WaitingTx(amount: amount);
    if (!spi.transactionFlowState.finished) {
      if (spi.status == SpiStatus.PAIRED_CONNECTING) {
        content = WaitingConnection(amount: amount);
      }
      if (spi.transactionFlowState.awaitingSignatureCheck) {
        content = SignatureRequire(amount: amount);
      }
      if (spi.transactionFlowState.attemptingToCancel) {
        content = AttemptingCancelTransaction(amount: amount);
      }
    } else {
      if (spi.transactionFlowState.success == 'UNKNOWN') {
        content = TxUnknown(
          amount: amount,
          retry: _retry,
        );
      }
      if (spi.transactionFlowState.success == 'SUCCESS') {
        content = TxSuccessful(amount: amount);
      }
      if (spi.transactionFlowState.success == 'FAILED') {
        content = TxFaild(
          amount: amount,
          retry: _retry,
        );
      }
    }

    return SimpleDialog(
      contentPadding: EdgeInsets.all(0),
      titlePadding: EdgeInsets.fromLTRB(40, 0, 40, 0),
      title: Text('EFTPOS - Order XYZ'),
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.5,
          child: content,
        ),
      ],
    );
  }
}
