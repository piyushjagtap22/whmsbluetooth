import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothDevice? connectedDevice;
  List<BluetoothService>? services;
  BluetoothCharacteristic? characteristic;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((results) {
      // Find your Arduino device
      var arduinoDevice =
          results.firstWhere((result) => result.device.name == "Arduino");
      if (arduinoDevice != null) {
        _connectToDevice(arduinoDevice.device);
      }
    });
  }

  bool showAvailableDevices = false; // Control visibility

  void _showAvailableDevices() {
    setState(() {
      showAvailableDevices = true;
    });
  }

  void _startScan() {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((results) {
      // Find your Arduino device
      var arduinoDevice =
          results.firstWhere((result) => result.device.platformName == "WHMS");
      if (arduinoDevice != null) {
        _connectToDevice(arduinoDevice.device);
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    await device.connect();
    services = await device.discoverServices();
    characteristic = services!
        .firstWhere(
            (service) => service.uuid == "00002a05-0000-1000-8000-00805f9b34fb")
        .characteristics
        .first;
    setState(() {
      connectedDevice = device;
    });
  }

  void _sendData(String data) async {
    if (characteristic != null) {
      await characteristic!.write(utf8.encode(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth App'),
      ),
      body: Column(
        children: [
          if (showAvailableDevices)
            Expanded(
              child: StreamBuilder(
                stream: FlutterBluePlus.scanResults,
                builder: (context, snapshot) {
                  return ListView.builder(
                    itemCount: snapshot.data?.length,
                    itemBuilder: (context, index) {
                      var device = snapshot.data?[index].device;
                      return ListTile(
                        title: Text(device!.platformName),
                        onTap: () => _connectToDevice(device),
                      );
                    },
                  );
                },
              ),
            ),
          ElevatedButton(
            onPressed: _startScan,
            child: Text('Scan Devices'),
          ),
          if (connectedDevice != null)
            Text('Connected to: ${connectedDevice!.name}'),
          if (connectedDevice != null)
            TextField(
              decoration: InputDecoration(hintText: 'Enter data to send'),
              onSubmitted: (value) => _sendData(value),
            ),
          if (connectedDevice != null)
            ElevatedButton(
              onPressed: () {
                // Disconnect from the device
                connectedDevice!.disconnect();
                setState(() {
                  connectedDevice = null;
                  services = null;
                  characteristic = null;
                });
              },
              child: Text('Disconnect'),
            ),
        ],
      ),
    );
  }
}
