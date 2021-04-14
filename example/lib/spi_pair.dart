import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi_example/spi_model.dart';
import 'package:provider/provider.dart';

class Pair extends StatelessWidget {
  const Pair({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAIR'),
      ),
      body: Container(
        padding: EdgeInsets.all(15),
        child: ListView(
          children: [
            TextFormField(
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'POS ID',
                ),
                maxLines: 1,
                readOnly: spi.status != SpiStatus.UNPAIRED,
                initialValue: spi.posId,
                onChanged: (value) {
                  spi.updatePosId(value);
                }),
            SizedBox(
              height: 10,
            ),
            TextFormField(
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'EFTPOS ID',
              ),
              maxLines: 1,
              readOnly: spi.status != SpiStatus.UNPAIRED,
              initialValue: spi.eftPosId,
              onChanged: (value) {
                spi.updatePosId(value);
              },
            ),
            SizedBox(
              height: 10,
            ),
            TextFormField(
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'EFTPOS ADDRESS',
              ),
              maxLines: 1,
              readOnly: spi.status != SpiStatus.UNPAIRED,
              initialValue: spi.eftPosAddress,
              onChanged: (value) {
                spi.updateEftPosAddress(value);
              },
            ),
            ListTile(
              title: Text(
                'Automatic Address:',
              ),
              trailing: Switch(
                value: spi.autoAddress,
                onChanged: spi.status == SpiStatus.UNPAIRED
                    ? (value) {
                        spi.updateAutoAddress(value);
                      }
                    : null,
              ),
            ),
            ListTile(
              title: Text(
                'TEST MODE:',
              ),
              trailing: Switch(
                value: spi.testMode,
                onChanged: spi.status == SpiStatus.UNPAIRED
                    ? (value) {
                        spi.updateTestMode(value);
                      }
                    : null,
              ),
            ),
            Divider(),
            Text(
              'STATUS: ${EnumToString.convertToString(spi.status)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Divider(),
            ElevatedButton(onPressed: () => spi.save(), child: Text('SAVE')),
            spi.status == SpiStatus.UNPAIRED
                ? ElevatedButton(
                    onPressed: () => spi.pair(), child: Text('PAIR'))
                : ElevatedButton(
                    onPressed: () => spi.unpair(), child: Text('UNPAIR'))
          ],
        ),
      ),
    );
  }
}
