import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spi_example/spi_model.dart';

class UnpairDialog extends StatelessWidget {
  UnpairDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(0),
      titlePadding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
      title: const Text('Unpairing Successful'),
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              const Text(
                  'Should the EFTPOS terminal remain paired, press Enter + 3 on the EFTPOS terminal to complete unpairing process.'),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context), child: const Text('OK'))
            ],
          ),
        ),
      ],
    );
  }
}
