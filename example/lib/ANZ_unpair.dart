
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'anz_state.dart';

class UnpairUI extends StatelessWidget {
  const UnpairUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnzState>(
      builder: (context, anzState, child) {
        final status = anzState.unpairStatus;
        String text;
        Color color;
        switch (status) {
          case ANZUnpairStatus.disposed:
            text = 'Unpair Completed';
            color = Colors.green;
            break;
          case ANZUnpairStatus.failed:
            text = 'Unpair Failed';
            color = Colors.red;
            break;
          case ANZUnpairStatus.idle:
          default:
            text = '';
            color = Colors.grey;
        }
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_off, color: color, size: 40),
                const SizedBox(height: 16),
                Text(
                  text,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                if (status == ANZUnpairStatus.disposed || status == ANZUnpairStatus.failed)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
