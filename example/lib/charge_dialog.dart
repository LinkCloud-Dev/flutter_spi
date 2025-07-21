import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'anz_state.dart';

class ChargeDialog extends StatefulWidget {
  const ChargeDialog({Key? key}) : super(key: key);

  @override
  State<ChargeDialog> createState() => _ChargeDialogState();
}

class _ChargeDialogState extends State<ChargeDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AnzState>(
      builder: (context, anzState, child) {
        return AlertDialog(
          title: _buildTitle(anzState),
          content: _buildContent(anzState),
          actions: _buildActions(anzState),
        );
      },
    );
  }

  Widget _buildTitle(AnzState anzState) {
    switch (anzState.transactionStatus) {
      case ANZTransactionStatus.processing:
        return const Text('Processing Payment');
      case ANZTransactionStatus.completed:
        return const Text('Payment Successful');
      case ANZTransactionStatus.failed:
        return const Text('Payment Failed');
      default:
        return const Text('Payment');
    }
  }

  Widget _buildContent(AnzState anzState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIcon(anzState),
        const SizedBox(height: 16),
        _buildStatusText(anzState),
        const SizedBox(height: 16),
        _buildTransactionDetails(anzState),
        if (anzState.lastTransaction?.errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorMessage(anzState),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(AnzState anzState) {
    switch (anzState.transactionStatus) {
      case ANZTransactionStatus.processing:
        return const CircularProgressIndicator();
      case ANZTransactionStatus.completed:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        );
      case ANZTransactionStatus.failed:
        return const Icon(
          Icons.error,
          color: Colors.red,
          size: 48,
        );
      default:
        return const Icon(
          Icons.payment,
          color: Colors.blue,
          size: 48,
        );
    }
  }

  Widget _buildStatusText(AnzState anzState) {
    switch (anzState.transactionStatus) {
      case ANZTransactionStatus.processing:
        return const Text(
          'Processing your payment...',
          style: TextStyle(fontSize: 16),
        );
      case ANZTransactionStatus.completed:
        return const Text(
          'Payment completed successfully!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
      case ANZTransactionStatus.failed:
        return const Text(
          'Payment failed',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
      default:
        return const Text(
          'Ready to process payment',
          style: TextStyle(fontSize: 16),
        );
    }
  }

  Widget _buildTransactionDetails(AnzState anzState) {
    final transaction = anzState.lastTransaction;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount:'),
              Text(
                '\$15.00',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (transaction?.posRefId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transaction ID:'),
                Expanded(
                  child: Text(
                    transaction!.posRefId!,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (transaction?.transRef != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reference:'),
                Expanded(
                  child: Text(
                    transaction!.transRef!,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (transaction?.cardRef != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Card:'),
                Expanded(
                  child: Text(
                    transaction!.cardRef!,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage(AnzState anzState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              anzState.lastTransaction!.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(AnzState anzState) {
    switch (anzState.transactionStatus) {
      case ANZTransactionStatus.processing:
        return []; // 处理中不显示按钮
      case ANZTransactionStatus.completed:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ];
      case ANZTransactionStatus.failed:
        return [
          TextButton(
            onPressed: () {
              // 重新开始交易，但不关闭对话框
              anzState.startTransaction(
                'retry_transaction_${DateTime.now().millisecondsSinceEpoch}',
                1500,
              );
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ];
      default:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ];
    }
  }
} 