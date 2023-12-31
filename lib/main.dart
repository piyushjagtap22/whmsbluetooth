import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Serial Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice targetDevice;
  late BluetoothCharacteristic targetCharacteristic;

  TextEditingController textController = TextEditingController();

  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  void initBluetooth() async {
    await flutterBlue.isOn;
    flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.name == "WHMS") {
          targetDevice = result.device;
          connectToDevice();
        }
      }
    });
    flutterBlue.startScan();
  }

  void connectToDevice() async {
    await targetDevice.connect();
    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service) {
      service.characteristics.forEach((characteristic) {
        if (characteristic.uuid.toString() ==
            "00002a05-0000-1000-8000-00805f9b34fb") {
          targetCharacteristic = characteristic;
        }
      });
    });
  }

  void sendText() {
    if (targetCharacteristic != null) {
      String textToSend = textController.text;
      List<int> bytes = textToSend.codeUnits;
      targetCharacteristic.write(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: textController,
                decoration: InputDecoration(labelText: 'Enter Text'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: sendText,
                child: Text('Send'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
