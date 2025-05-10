import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'custom_drawer.dart';
import 'services/bluetooth_service.dart';
import 'services/storage_service.dart';
import 'widgets/previous_devices_widget.dart';
import 'widgets/bluetooth_troubleshooting_widget.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isScanning = false;
  List<BluetoothDevice> _foundPairedHcDevices = [];
  List<Map<String, String>> _previousDevices = [];
  bool _isConnected = false;
  String _statusText = 'Not connected';
  String _debugScanLog = "";
  String _debugFilteredScanLog = "";
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  List<ScanResult> _currentScanResults = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadPreviousDevices();

    final manager = Provider.of<BluetoothManager>(context, listen: false);
    setState(() {
      _isConnected = manager.isConnected;
      if (_isConnected) {
        _statusText = manager.connectionStatus;
      }
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _currentScanResults = results;
      });
    }, onError: (e) {
      print("Error listening to scan results: $e");
      setState(() {
        _statusText = "Scan Error: $e";
        _isScanning = false;
      });
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _loadPreviousDevices() async {
    final devices = await StorageService.getConnectedDevices();
    setState(() {
      _previousDevices = devices;
    });
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.bluetoothScan.status;
    if (status.isDenied) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    }
  }

  Future<void> _loadPairedHcDevices() async {
    setState(() {
      _isScanning = true;
      _foundPairedHcDevices = [];
      _currentScanResults = [];
      _debugScanLog = "Scanning for devices...\n";
      _debugFilteredScanLog = "";
      _statusText = 'Scanning for HC-05 devices...';
    });

    try {
      await _checkPermissions();
      var scanStatus = await Permission.bluetoothScan.status;
      var connectStatus = await Permission.bluetoothConnect.status;

      if (!scanStatus.isGranted || !connectStatus.isGranted) {
        setState(() {
          _isScanning = false;
          _statusText = 'Bluetooth permissions denied. Please grant permissions in settings.';
          _debugScanLog = "Permissions denied.";
        });
        return;
      }

      await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
      await Future.delayed(Duration(seconds: 6));
      _processScanResults();
    } catch (e) {
      print('Error scanning for devices: $e');
      setState(() {
        _isScanning = false;
        _statusText = 'Error scanning: $e';
        _debugScanLog = "Scan Error: $e\n";
      });
    }
  }

  void _processScanResults() {
    String allScannedDevicesLog = 'All Scanned Devices (${_currentScanResults.length}):\n';
    for (var result in _currentScanResults) {
      allScannedDevicesLog += '- Name: "${result.advertisementData.advName}", PName: "${result.device.platformName}", LName: "${result.device.localName}", ID: ${result.device.remoteId}, RSSI: ${result.rssi}\n';
    }

    // Populate _foundPairedHcDevices with ALL unique scanned devices
    final allUniqueDevices = <BluetoothDevice>[];
    final seenDeviceIds = <String>{};
    for (var result in _currentScanResults) {
      if (seenDeviceIds.add(result.device.remoteId.toString())) {
        allUniqueDevices.add(result.device);
      }
    }

    // Keep the HC-05 filtering logic for debug purposes
    final filteredHc05Devices = _currentScanResults.where((result) {
      String normalizeName(String name) {
        return name.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
      }

      final advName = normalizeName(result.advertisementData.advName);
      final pName = normalizeName(result.device.platformName);
      final lName = normalizeName(result.device.localName);

      final targetIdentifier = 'hc05';

      if (advName.contains(targetIdentifier)) return true;
      if (pName.contains(targetIdentifier)) return true;
      if (lName.contains(targetIdentifier)) return true;

      return false;
    }).map((result) => result.device).toList();

    final uniqueFilteredHc05Devices = <BluetoothDevice>[];
    final seenFilteredIds = <String>{};
    for (var device in filteredHc05Devices) {
      if (seenFilteredIds.add(device.remoteId.toString())) {
        uniqueFilteredHc05Devices.add(device);
      }
    }

    String filteredScanLog = 'Filtered HC-05 Devices from Scan (${uniqueFilteredHc05Devices.length}):\n';
    for (var dev in uniqueFilteredHc05Devices) {
      filteredScanLog += '- PName: "${dev.platformName}", LName: "${dev.localName}", ID: ${dev.remoteId}\n';
    }

    setState(() {
      _foundPairedHcDevices = allUniqueDevices; // Show all unique devices
      _isScanning = false;
      _debugScanLog = allScannedDevicesLog;
      _debugFilteredScanLog = filteredScanLog; // This still shows only HC-05 for debug
      if (_foundPairedHcDevices.isEmpty) {
        _statusText = "No Bluetooth devices found via scan.";
      } else {
        _statusText = 'Found ${_foundPairedHcDevices.length} device(s) via scan. Select to connect.';
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _statusText = 'Connecting to ${device.platformName ?? 'Unknown Device'}...';
    });

    final manager = Provider.of<BluetoothManager>(context, listen: false);
    bool success = await manager.connectToDevice(device);

    setState(() {
      _isConnected = success;
      if (success) {
        _statusText = 'Connected to ${device.platformName ?? 'Unknown Device'}';
      } else {
        _statusText = 'Connection failed';
      }
    });
  }

  Future<void> _connectToPreviousDevice(String deviceId) async {
    setState(() {
      _statusText = 'Connecting to previous device...';
    });

    try {
      BluetoothDevice? targetDevice;

      for (var device in _foundPairedHcDevices) {
        if (device.remoteId.toString() == deviceId) {
          targetDevice = device;
          break;
        }
      }

      if (targetDevice == null) {
        print("Device ID $deviceId not found in current scan results. Previous device connection might fail if not discoverable.");
      }

      if (targetDevice != null) {
        final manager = Provider.of<BluetoothManager>(context, listen: false);
        bool success = await manager.connectToDevice(targetDevice);

        setState(() {
          _isConnected = success;
          if (success) {
            _statusText = 'Connected to ${targetDevice?.platformName ?? "Unknown Device"}';
          } else {
            _statusText = 'Connection failed';
          }
        });
      } else {
        setState(() {
          _statusText = 'Device not found. Try scanning again.';
        });
      }
    } catch (e) {
      print('Error connecting to previous device: $e');
      setState(() {
        _statusText = 'Error: $e';
      });
    }
  }

  Future<void> _disconnectDevice() async {
    setState(() {
      _statusText = 'Disconnecting...';
    });

    final manager = Provider.of<BluetoothManager>(context, listen: false);
    await manager.disconnect();

    setState(() {
      _isConnected = false;
      _statusText = 'Disconnected';
    });
  }

  Future<void> _connectToMacAddress(String macAddress) async {
    setState(() {
      _statusText = 'Attempting to connect to MAC: $macAddress...';
    });

    BluetoothDevice? targetDevice;

    // 1. Check current scan results
    for (var scanResult in _currentScanResults) {
      if (scanResult.device.remoteId.toString() == macAddress) {
        targetDevice = scanResult.device;
        print("Device $macAddress found in current scan results.");
        break;
      }
    }

    // 2. If not found in scan results, check bonded devices
    if (targetDevice == null) {
      print("Device $macAddress not in scan results, checking bonded devices...");
      try {
        // Ensure permissions are checked before trying to get bonded devices
        await _checkPermissions(); 
        var connectPermission = await Permission.bluetoothConnect.status;
        if (!connectPermission.isGranted) {
          setState(() {
            _statusText = 'Bluetooth connect permission denied.';
          });
          return;
        }

        List<BluetoothDevice> bondedDevices = await FlutterBluePlus.bondedDevices;
        print("Bonded devices found: ${bondedDevices.length}");
        for (var device in bondedDevices) {
          print("Checking bonded device: ${device.platformName} - ${device.remoteId.toString()}");
          if (device.remoteId.toString() == macAddress) {
            targetDevice = device;
            print("Device $macAddress found in bonded devices.");
            break;
          }
        }
      } catch (e) {
        print("Error fetching bonded devices: $e");
        setState(() {
          _statusText = 'Error fetching bonded devices: $e';
        });
        return;
      }
    }

    if (targetDevice != null) {
      await _connectToDevice(targetDevice); // Use existing connection logic
    } else {
      setState(() {
        _statusText = 'Device with MAC $macAddress not found.';
        print("Device $macAddress not found in scan results or bonded devices.");
      });
    }
  }

  void _createTestBin() {
    final manager = Provider.of<BluetoothManager>(context, listen: false);

    final random = DateTime.now().millisecond / 1000.0 * 100;
    final fillLevel = (random % 100).clamp(10.0, 95.0);

    manager.createTestBin(fillLevel);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test bin created with fill level: ${fillLevel.toStringAsFixed(2)}%'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: Color(0xFF77BA69),
              size: 30,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(''),
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF77BA69),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Bluetooth Connection',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF77BA69),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF77BA69)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Status: $_statusText',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_isConnected)
                            ElevatedButton(
                              onPressed: _disconnectDevice,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Disconnect'),
                            ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isScanning ? null : _loadPairedHcDevices,
                              icon: Icon(Icons.devices_other),
                              label: Text(_isScanning ? 'Scanning...' : 'Scan for HC-05'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF77BA69),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _createTestBin,
                            icon: Icon(Icons.science),
                            label: Text('Test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_previousDevices.isNotEmpty && !_isConnected)
                    PreviousDevicesWidget(
                      previousDevices: _previousDevices,
                      onConnectPressed: _connectToPreviousDevice,
                      isConnected: _isConnected,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      color: Colors.grey[200],
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("--- DEBUG INFO ---", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text("Scan Log:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_debugScanLog),
                          SizedBox(height: 10),
                          Text("Filtered Scan Results:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_debugFilteredScanLog),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _connectToMacAddress("00:25:03:01:26:70"),
                            child: Text("Connect to 00:25:03:01:26:70"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                          ),
                          SizedBox(height: 5),
                          Text("--- END DEBUG INFO ---", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  if (_foundPairedHcDevices.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scanned Devices',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF77BA69),
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF77BA69).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _foundPairedHcDevices.length,
                              itemBuilder: (context, index) {
                                final device = _foundPairedHcDevices[index];

                                String displayName = device.platformName;
                                if (displayName.isEmpty) {
                                  displayName = device.localName;
                                }
                                if (displayName.isEmpty) {
                                  final scanResult = _currentScanResults.firstWhere(
                                    (r) => r.device.remoteId == device.remoteId,
                                    orElse: () => ScanResult(
                                      device: device,
                                      advertisementData: AdvertisementData(
                                        advName: '',
                                        txPowerLevel: null,
                                        connectable: false,
                                        manufacturerData: {},
                                        serviceData: {},
                                        serviceUuids: [],
                                        appearance: 0,
                                      ),
                                      rssi: -100,
                                      timeStamp: DateTime.now(),
                                    ),
                                  );
                                  if (scanResult.advertisementData.advName.isNotEmpty) {
                                    displayName = scanResult.advertisementData.advName;
                                  } else {
                                    displayName = 'Unknown device (${device.remoteId})';
                                  }
                                }

                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text('ID: ${device.remoteId.toString()}'),
                                    trailing: ElevatedButton(
                                      onPressed: () => _connectToDevice(device),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF77BA69),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text('Connect'),
                                    ),
                                    onTap: () => _connectToDevice(device),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!_isConnected && _previousDevices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_searching,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Press 'Scan for HC-05' to list sensors nearby. Ensure your HC-05 sensor is powered on and within range.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 30),
                            BluetoothTroubleshootingWidget(
                              onScanPressed: _loadPairedHcDevices,
                            ),
                          ],
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 15),
            color: Color(0xFF77BA69),
            child: Text(
              'Right on Time, No Overflow Crime!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}