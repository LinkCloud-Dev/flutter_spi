import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spi/flutter_spi.dart';
import 'package:flutter_spi_example/spi_transaction.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spi_example/spi_model.dart';
import 'package:flutter_spi_example/spi_pair.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SpiModel(),
      child: MaterialApp(
        title: 'Spi Demo',
        initialRoute: '/',
        routes: {
          '/': (context) => Home(),
          '/pair': (context) => Pair(),
          '/purcharse': (context) => Transaction(),
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    _initSpi();
    super.initState();
  }

  void _initSpi() async {
    var spi = Provider.of<SpiModel>(context, listen: false);
    spi.init();
    FlutterSpi.handleMethodCall(spi.subscribeSpiEvents);
  }

  @override
  Widget build(BuildContext context) {
    var spi = Provider.of<SpiModel>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: Text('Spi Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.all(15),
              child:
                  Text('STATUS: ${EnumToString.convertToString(spi.status)}'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/pair'),
              child: Text('Pair'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/purcharse'),
              child: Text('Purcharse'),
            ),
          ],
        ),
      ),
    );
  }
}
