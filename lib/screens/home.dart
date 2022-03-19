import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = 'home/';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

FlutterBluetoothSerial bleutooth = FlutterBluetoothSerial.instance;

BluetoothConnection? connection;

List<BluetoothDevice> _devices = [];
BluetoothDevice? _device;
bool _connected = false;
bool _pressed = false;

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _onValue = TextEditingController();
  final TextEditingController _offValue = TextEditingController();

  final TextEditingController _maxValue = TextEditingController();
  double _sliderValue = 0;

  bool _isConnectingLoading = false;
  bool _isRefreshingLoading = false;
  int _selectedInt = -1;

  final List<bool> _isOpen = [
    false,
    false,
  ];
  @override
  void initState() {
    super.initState();
    scanDevices();
    _getDeviceItems();
  }

  scanDevices() async {
    List<BluetoothDevice> devices = [];
    devices = await bleutooth.getBondedDevices();

    if (!mounted) {
      return;
    }
    setState(() {
      _devices = devices;
      _isRefreshingLoading = false;
    });
  }

  List<DropdownMenuItem<BluetoothDevice>> items = [];
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    items.clear();
    if (_devices.isNotEmpty) {
      for (var device in _devices) {
        items.add(
          DropdownMenuItem(
            child: Text(
              device.name.toString(),
            ),
            value: device,
          ),
        );
      }
    }

    return items;
  }

  void _connect() {
    if (_selectedInt < 0) {
      show("No Device Selected");
    } else {
      setState(() {
        _isConnectingLoading = true;
      });
      bleutooth.isEnabled.then((isConnected) {
        if (isConnected == true) {
          BluetoothConnection.toAddress(
            _device!.address,
          )
              .timeout(
            const Duration(seconds: 10),
          )
              .then((value) {
            setState(() {
              connection = value;
              _connected = true;
              _pressed = false;
              _isConnectingLoading = false;
            });
            show("Device Connected successfully");
          }).catchError((error) {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('An Error has occured'),
                    content: const Text(
                        "Please Try to check the device you are connecting to, or check your bluetooth."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Okay'),
                      ),
                    ],
                  );
                });
            setState(
              () {
                _pressed = false;
                _isConnectingLoading = false;
              },
            );
          });
        }
      });
    }
  }

  void _disconnect() {
    setState(() {
      _isOpen.fillRange(
        0,
        _isOpen.length,
        false,
      );
      _isConnectingLoading = true;
      _connected = false;
      _pressed = false;
      _selectedInt = -1;
    });

    connection!.close();
    setState(() {
      _isConnectingLoading = false;
    });
    show("Device Disconnected");
  }

  Future show(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 100),
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        duration: duration,
      ),
    );
  }

  void _sendOnMessageToBluetooth() {
    bleutooth.isAvailable.then((isConnected) {
      if (isConnected!) {
        connection!.output.add(ascii.encode("${_onValue.text} \r\n"));
        show('Device Turned On');
      } else {
        _disconnect();
      }
    });
  }

  void _sendOffMessageToBluetooth() {
    bleutooth.isAvailable.then((isConnected) {
      if (isConnected!) {
        connection!.output.add(ascii.encode("${_offValue.text} \r\n"));
        show('Device Turned Off');
      } else {
        _disconnect();
      }
    });
  }

  void _sendDoubleMessageToBluetooth() {
    bleutooth.isAvailable.then((isConnect) {
      if (isConnect!) {
        connection!.output.add(ascii.encode("${_sliderValue.toString()} \r\n"));
        show("Value Sent To Device");
      } else {
        _disconnect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arduino Bluetooth Controller'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isConnectingLoading
          ? const CircularProgressIndicator()
          : _devices.isEmpty
              ? _isRefreshingLoading
                  ? const CircularProgressIndicator()
                  : FloatingActionButton.extended(
                      onPressed: () {
                        setState(() {
                          _isRefreshingLoading = true;
                        });
                        scanDevices();
                      },
                      label: const Text('Refresh'),
                      icon: const Icon(Icons.refresh),
                    )
              : FloatingActionButton.extended(
                  onPressed: _pressed
                      ? null
                      : _connected
                          ? _disconnect
                          : _connect,
                  icon: const Icon(Icons.cast_connected_outlined),
                  backgroundColor: _connected ? Colors.grey : null,
                  label: Text(
                    _connected ? 'Disconnect' : 'Connect',
                  ),
                ),
      body: RefreshIndicator(
        onRefresh: () => scanDevices(),
        child: _devices.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      'There is No Devices Found',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 25,
                      ),
                    ),
                    Text(
                      'Please Check Your Bluetooth and your devices connection.\nThank You!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.only(
                  bottom: 70,
                ),
                children: <Widget>[
                  SizedBox(
                    width: width - 20,
                    height: height * 0.3,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              Text(
                                "All Paired Devices",
                                style: TextStyle(
                                  fontSize: 24,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const Text(
                                "Click to choose the Device",
                                style: TextStyle(color: Colors.black),
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                              itemCount: _getDeviceItems().length,
                              itemBuilder: (BuildContext context, int i) {
                                return ListTile(
                                  trailing: Icon(
                                    Icons.device_hub,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  title: items[i],
                                  onTap: !_connected
                                      ? () {
                                          setState(() {
                                            _selectedInt = i;
                                            _device = items[i].value;
                                          });
                                        }
                                      : null,
                                  leading: Icon(
                                    _selectedInt == i
                                        ? Icons.check
                                        : Icons.circle_outlined,
                                    color: _connected
                                        ? Colors.grey
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              }),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ExpansionPanelList(
                      expansionCallback: _connected
                          ? (i, isOpen) {
                              setState(() {
                                _isOpen[i] = !isOpen;
                              });
                            }
                          : (i, _) => show("Please Connect Your Device"),
                      children: [
                        ExpansionPanel(
                          headerBuilder: (context, isOpen) {
                            return Center(
                              child: Text(
                                "Switcher",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 25,
                                ),
                              ),
                            );
                          },
                          body: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: width * 0.25,
                                    child: TextField(
                                      controller: _onValue,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'On Value',
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.25,
                                    child: TextField(
                                      controller: _offValue,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Off Value',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed:
                                        _connected && _onValue.text.isNotEmpty
                                            ? _sendOnMessageToBluetooth
                                            : null,
                                    child: const Text("ON"),
                                  ),
                                  TextButton(
                                    onPressed:
                                        _connected && _offValue.text.isNotEmpty
                                            ? _sendOffMessageToBluetooth
                                            : null,
                                    child: const Text("OFF"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isExpanded: _isOpen[0],
                        ),
                        ExpansionPanel(
                          headerBuilder: (context, isOpen) {
                            return Center(
                              child: Text(
                                "Slider ",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 25,
                                ),
                              ),
                            );
                          },
                          body: Column(
                            children: [
                              SizedBox(
                                width: width - 100,
                                child: TextField(
                                  controller: _maxValue,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Insert Maximum Value',
                                  ),
                                ),
                              ),
                              Slider(
                                value: _sliderValue,
                                max: _maxValue.text.isEmpty
                                    ? 10
                                    : double.parse(_maxValue.text),
                                min: 0,
                                divisions: _maxValue.text.isEmpty
                                    ? 10
                                    : int.parse(_maxValue.text),
                                label: _sliderValue.toString(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _sliderValue = newValue;
                                  });
                                  _sendDoubleMessageToBluetooth();
                                },
                              ),
                            ],
                          ),
                          isExpanded: _isOpen[1],
                        )
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
