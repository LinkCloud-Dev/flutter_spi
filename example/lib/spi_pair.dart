import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi_example/spi/paring_dialog.dart';
import 'package:flutter_spi_example/spi_model.dart';
import 'package:flutter_spi_example/spi/unpair_dialog.dart';

class Pair extends StatelessWidget {
  const Pair({Key? key}) : super(key: key);

  void _pair(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: false);
    spi.pair();
    _showDialog<String>(
      context: context,
      child: PairingDialog(),
    );
  }

  void _unpair(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: false);
    spi.unpair();
    _showDialog<String>(
      context: context,
      child: UnpairDialog(),
    );
  }

  Future<void> _showDialog<T>({required BuildContext context, required Widget child}) async {
    await showDialog<T>(
      barrierDismissible: false,
      context: context,
      builder: (context) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAIR'),
      ),
      body: Container(
        padding: const EdgeInsets.all(15),
        child: ListView(
          children: [
            TextFormField(
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'POS ID',
                ),
                maxLines: 1,
                maxLength: 16,
                readOnly: spi.status != SpiStatus.UNPAIRED,
                initialValue: spi.posId,
                onChanged: (value) {
                  spi.updatePosId(value);
                }),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'SERIAL NUMBER',
                ),
                maxLines: 1,
                maxLength: 16,
                readOnly: spi.status != SpiStatus.UNPAIRED,
                initialValue: spi.serialNumber,
                onChanged: (value) {
                  spi.updateSerialNumber(value);
                }),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'EFTPOS ADDRESS',
              ),
              maxLines: 1,
              readOnly: spi.status != SpiStatus.UNPAIRED,
              initialValue: spi.eftPosAddress,
              onChanged: (value) {
                spi.updateEftPosAddress(value);
              },
            ),
            const Divider(),
            (spi.status == SpiStatus.UNPAIRED && spi.secrets != null)
                ? Container(
                    margin: const EdgeInsets.all(15),
                    child: const Text('STATUS: DISCONNECTED'),
                  )
                : Container(
                    margin: const EdgeInsets.all(15),
                    child: Text(
                        'STATUS: ${EnumToString.convertToString(spi.status)}'),
                  ),
            const Divider(),
            ElevatedButton(onPressed: () => spi.save(), child: const Text('SAVE')),
            (spi.status == SpiStatus.UNPAIRED && spi.secrets == null)
                ? ElevatedButton(
                    onPressed: () => _pair(context), child: const Text('PAIR'))
                : const SizedBox.shrink(),
            (spi.secrets != null)
                ? ElevatedButton(
                    onPressed: () => _unpair(context),
                    child: const Text('UNPAIR'),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
