import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart' as fb;
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
  final fb.FlutterBluetoothSerial _bluetooth = fb.FlutterBluetoothSerial.instance;
  bool _isScanning = false;
  List<fb.BluetoothDevice> _foundDevices = [];
  List<Map<String, String>> _previousDevices = [];
  bool _isConnected = false;
  String _statusText = 'Not connected';
  String _debugScanLog = "";
  String _debugFilteredScanLog = "";

  StreamSubscription<fb.BluetoothDiscoveryResult>? _discoveryStreamSubscription;
  List<fb.BluetoothDiscoveryResult> _discoveryResults = [];
  BluetoothManager? _bluetoothManager;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadPreviousDevices();

    _bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);
    _bluetoothManager?.addListener(_updateConnectionStateFromManager);
    _updateConnectionStateFromManager();
  }

  void _updateConnectionStateFromManager() {
    if (mounted && _bluetoothManager != null) {
      setState(() {
        _isConnected = _bluetoothManager!.isConnected;
        _statusText = _bluetoothManager!.connectionStatus;
      });
    }
  }

  @override
  void dispose() {
    _discoveryStreamSubscription?.cancel();
    if (_isScanning) {
      _bluetooth.cancelDiscovery();
    }
    _bluetoothManager?.removeListener(_updateConnectionStateFromManager);
    super.dispose();
  }

  Future<void> _loadPreviousDevices() async {
    final devices = await StorageService.getConnectedDevices();
    if (mounted) {
      setState(() {
        _previousDevices = devices;
      });
    }
  }

  Future<void> _checkPermissions() async {
    var locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      await Permission.location.request();
    }

    if (Theme.of(context).platform == TargetPlatform.android) {
      var scanStatus = await Permission.bluetoothScan.status;
      var connectStatus = await Permission.bluetoothConnect.status;
      if (scanStatus.isDenied || connectStatus.isDenied) {
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();
      }
    }
  }

  Future<void> _startDiscovery() async {
    await _checkPermissions();

    var serviceStatus = await Permission.location.serviceStatus;
    // Detailed permission status logging
    String initialDebugLog = "Starting _startDiscovery. Initial Permission Statuses:\n";
    initialDebugLog += "Location Service Enabled: ${serviceStatus == ServiceStatus.enabled}\n";
    var locStatus = await Permission.location.status;
    initialDebugLog += "Permission.location status: $locStatus\n";
    if (Theme.of(context).platform == TargetPlatform.android) {
      var scanStatus = await Permission.bluetoothScan.status;
      var connectStatus = await Permission.bluetoothConnect.status;
      initialDebugLog += "Permission.bluetoothScan status: $scanStatus\n";
      initialDebugLog += "Permission.bluetoothConnect status: $connectStatus\n";
    }
    if (mounted) {
      setState(() {
        _debugScanLog = initialDebugLog; // Overwrite or prepend to existing debug log
      });
    }

    if (serviceStatus != ServiceStatus.enabled) {
      if (mounted) {
        String serviceStatusMessage = 'Location services are disabled. Please enable them for Bluetooth discovery.';
        if (serviceStatus == ServiceStatus.notApplicable) {
          serviceStatusMessage = 'Location services are not applicable on this device for discovery.';
        }
        setState(() {
          _statusText = serviceStatusMessage;
          _debugScanLog = "Location service status: $serviceStatus. User prompted to open settings.";
          _isScanning = false;
        });
        await openAppSettings();
      }
      return;
    }

    var locationStatus = await Permission.location.status; // Re-fetch after any prior requests
    if (!locationStatus.isGranted) {
      if (mounted) {
        // If it's just 'denied', try requesting one more time directly.
        // This handles the case where _checkPermissions might have requested, user denied,
        // and we want to give one clear shot before sending to settings.
        if (locationStatus == PermissionStatus.denied) {
          if (mounted) { // Ensure mounted before setState
            _debugScanLog += "Location permission was 'denied'. Requesting again directly...\n";
            setState(() {
              _statusText = "Requesting location permission...";
              _debugScanLog = _debugScanLog; // Update the log in UI
            });
          }
          final newStatus = await Permission.location.request();
          if (mounted) { // Ensure mounted before setState
            _debugScanLog += "Status after direct request: $newStatus\n";
            setState(() {
              _debugScanLog = _debugScanLog; // Update the log in UI
            });
          }
          locationStatus = newStatus; // Update status for the next check
        }

        // Now, if it's still not granted (either was never just 'denied', or the direct request also failed)
        if (!locationStatus.isGranted) {
          String permissionMessage = 'Location permission is required for Bluetooth discovery. ';
          if (locationStatus.isPermanentlyDenied) {
            permissionMessage += 'It has been permanently denied. Please grant it in app settings.';
          } else if (locationStatus.isRestricted) {
            permissionMessage += 'It is restricted and cannot be granted by the app.';
          } else { // .isDenied or other non-granted states
            permissionMessage += 'Please grant it in app settings. (Current status: $locationStatus)';
          }

          if (mounted) { // Ensure mounted before setState
            setState(() {
              _statusText = permissionMessage;
              _debugScanLog += "Location permission status check failed: $locationStatus. User will be prompted to open settings.\n";
              _isScanning = false;
            });
          }

          // Show an informative dialog before opening settings
          await showDialog(
            context: context, // Use the page's context
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text("Location Permission Needed"),
                content: Text(
                    "For Bluetooth scanning to find new devices, this app needs 'Location' permission.\n\n"
                    "When you tap 'Open Settings', please navigate to this app's permissions and ensure 'Location' is allowed (e.g., 'Allow while using app'). This is different from the 'Nearby devices' permission."),
                actions: <Widget>[
                  TextButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  TextButton(
                    child: Text("Open Settings"),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      openAppSettings(); // Open settings after dialog is dismissed
                    },
                  ),
                ],
              );
            },
          );
          return; // Important to return: permission not granted
        } else {
          // Permission was granted by the direct request.
          if (mounted) { // Ensure mounted before setState
            _debugScanLog += "Location permission granted after direct request.\n";
            setState(() {
              _debugScanLog = _debugScanLog; // Update the log in UI
            });
          }
        }
      } else { // not mounted
        return;
      }
    }
    // If we reach here, locationStatus IS granted.
    if (mounted) { // Ensure mounted before setState
      _debugScanLog += "Location permission is granted. Proceeding to Bluetooth permission checks.\n";
      setState(() {
        _debugScanLog = _debugScanLog;
      });
    }

    if (Theme.of(context).platform == TargetPlatform.android) {
      var scanStatus = await Permission.bluetoothScan.status;
      var connectStatus = await Permission.bluetoothConnect.status;

      if (!scanStatus.isGranted || !connectStatus.isGranted) {
        if (mounted) {
          String btPermissionMessage = 'Bluetooth Scan and Connect permissions are required. ';
          if (scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied) {
            btPermissionMessage += 'One or more have been permanently denied. Please grant them in app settings.';
          } else {
            btPermissionMessage += 'Please grant them in app settings.';
          }
          setState(() {
            _isScanning = false;
            _statusText = btPermissionMessage;
            _debugScanLog = "Bluetooth permissions not granted (Scan: $scanStatus, Connect: $connectStatus). User prompted to open settings.";
          });
          await openAppSettings();
        }
        return;
      }
    }

    setState(() {
      _isScanning = true;
      _foundDevices = [];
      _discoveryResults = [];
      _debugScanLog = "Scanning for devices...\n";
      _debugFilteredScanLog = "";
      _statusText = 'Scanning for devices...';
    });

    try {
      _discoveryStreamSubscription?.cancel();
      _discoveryStreamSubscription = _bluetooth.startDiscovery().listen(
        (fb.BluetoothDiscoveryResult result) {
          if (mounted) {
            setState(() {
              final existingIndexRaw = _discoveryResults.indexWhere((r) => r.device.address == result.device.address);
              if (existingIndexRaw >= 0) {
                _discoveryResults[existingIndexRaw] = result;
              } else {
                _discoveryResults.add(result);
              }
              _processDiscoveryResults();
            });
          }
        },
        onError: (dynamic error) {
          if (mounted) {
            print('Error during discovery: $error');
            setState(() {
              _isScanning = false;
              _statusText = 'Error scanning: $error';
              _debugScanLog += "Scan Error: $error\n";
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isScanning = false;
              if (_foundDevices.isEmpty) {
                _statusText = "No Bluetooth devices found.";
              } else {
                _statusText = 'Found ${_foundDevices.length} device(s). Select to connect.';
              }
              _debugScanLog += "Scan finished.\n";
            });
          }
        },
      );
    } catch (e) {
      print('Error starting discovery: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusText = 'Error starting scan: $e';
          _debugScanLog = "Scan Start Error: $e\n";
        });
      }
    }
  }

  void _processDiscoveryResults() {
    String allScannedDevicesLog = 'All Discovered Devices (${_discoveryResults.length}):\n';
    for (var result in _discoveryResults) {
      allScannedDevicesLog += '- Name: "${result.device.name ?? 'N/A'}", Address: ${result.device.address}, RSSI: ${result.rssi ?? 'N/A'}\n';
    }

    final allUniqueDevices = <fb.BluetoothDevice>[];
    final seenDeviceAddresses = <String>{};
    for (var result in _discoveryResults) {
      if (result.device.address.isNotEmpty) {
        if (seenDeviceAddresses.add(result.device.address)) {
          allUniqueDevices.add(result.device);
        }
      }
    }

    final filteredHc05Devices = _discoveryResults.where((result) {
      String normalizeName(String? name) {
        return (name ?? '').toLowerCase().replaceAll('-', '').replaceAll(' ', '');
      }
      final deviceName = normalizeName(result.device.name);
      final targetIdentifier = 'hc05';
      return deviceName.contains(targetIdentifier);
    }).map((result) => result.device).toList();

    final uniqueFilteredHc05Devices = <fb.BluetoothDevice>[];
    final seenFilteredAddresses = <String>{};
    for (var device in filteredHc05Devices) {
      if (seenFilteredAddresses.add(device.address)) {
        uniqueFilteredHc05Devices.add(device);
      }
    }

    String filteredScanLog = 'Filtered HC-05 Devices (${uniqueFilteredHc05Devices.length}):\n';
    for (var dev in uniqueFilteredHc05Devices) {
      filteredScanLog += '- Name: "${dev.name ?? 'N/A'}", Address: ${dev.address}\n';
    }

    if (mounted) {
      setState(() {
        _foundDevices = allUniqueDevices;
        _debugScanLog = allScannedDevicesLog;
        _debugFilteredScanLog = filteredScanLog;
        if (!_isScanning && _foundDevices.isEmpty) {
          _statusText = "No Bluetooth devices found.";
        } else if (!_isScanning) {
          _statusText = 'Found ${_foundDevices.length} device(s). Select to connect.';
        }
      });
    }
  }

  Future<void> _connectToDevice(fb.BluetoothDevice device) async {
    if (_isScanning) {
      await _bluetooth.cancelDiscovery();
      setState(() {
        _isScanning = false;
      });
    }

    final manager = Provider.of<BluetoothManager>(context, listen: false);
    await manager.connectToDevice(device);
  }

  Future<void> _connectToPreviousDevice(String deviceAddress) async {
    final manager = Provider.of<BluetoothManager>(context, listen: false);

    final deviceInfo = _previousDevices.firstWhere(
      (d) => d['id'] == deviceAddress,
      orElse: () => {'name': 'Unknown Device'}
    );
    final deviceName = deviceInfo['name'];

    final deviceToConnect = fb.BluetoothDevice(address: deviceAddress, name: deviceName);

    await manager.connectToDevice(deviceToConnect);
  }

  Future<void> _disconnectDevice() async {
    final manager = Provider.of<BluetoothManager>(context, listen: false);
    await manager.disconnect();
  }

  Future<void> _connectToMacAddress(String macAddress) async {
    if (_isScanning) {
      await _bluetooth.cancelDiscovery();
      setState(() {
        _isScanning = false;
      });
    }
    setState(() {
      _statusText = 'Attempting to connect to MAC: $macAddress...';
    });

    fb.BluetoothDevice? targetDevice;

    for (var device in _foundDevices) {
      if (device.address == macAddress) {
        targetDevice = device;
        print("Device $macAddress found in current discovery results.");
        break;
      }
    }

    if (targetDevice == null) {
      print("Device $macAddress not in discovery results, checking bonded devices...");
      try {
        await _checkPermissions();
        List<fb.BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();
        print("Bonded devices found: ${bondedDevices.length}");
        for (var device in bondedDevices) {
          print("Checking bonded device: ${device.name} - ${device.address}");
          if (device.address == macAddress) {
            targetDevice = device;
            print("Device $macAddress found in bonded devices.");
            break;
          }
        }
      } catch (e) {
        print("Error fetching bonded devices: $e");
        if (mounted) {
          setState(() {
            _statusText = 'Error fetching bonded devices: $e';
          });
        }
        return;
      }
    }

    if (targetDevice != null) {
      await _connectToDevice(targetDevice);
    } else {
      if (mounted) {
        setState(() {
          _statusText = 'Device with MAC $macAddress not found.';
          print("Device $macAddress not found in discovery or bonded devices.");
        });
      }
    }
  }

  void _createTestBin() {
    final manager = Provider.of<BluetoothManager>(context, listen: false);
    if (!manager.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bluetooth not connected. Cannot simulate test bin data.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final random = DateTime.now().millisecond / 1000.0 * 100;
    final fillLevel = (random % 100).clamp(10.0, 95.0);

    manager.createTestBin(fillLevel);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulated test bin data with fill level: ${fillLevel.toStringAsFixed(2)}%'),
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
                              onPressed: _isScanning ? null : _startDiscovery,
                              icon: Icon(Icons.devices_other),
                              label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
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
                      onConnectPressed: (String deviceId) => _connectToPreviousDevice(deviceId),
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
                          Text("Discovery Log:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_debugScanLog),
                          SizedBox(height: 10),
                          Text("Filtered HC-05 Discovery Results:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_debugFilteredScanLog),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _connectToMacAddress("00:24:10:01:1B:CB"),
                            child: Text("Connect to 00:24:10:01:1B:CB"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                          ),
                          SizedBox(height: 5),
                          Text("--- END DEBUG INFO ---", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  if (_foundDevices.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discovered Devices',
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
                              itemCount: _foundDevices.length,
                              itemBuilder: (context, index) {
                                final device = _foundDevices[index];
                                String displayName = device.name ?? 'Unknown Device';
                                final discoveryResult = _discoveryResults.firstWhere(
                                  (r) => r.device.address == device.address,
                                  orElse: () => fb.BluetoothDiscoveryResult(device: device, rssi: 0),
                                );
                                String subtitle = 'Address: ${device.address}';
                                if (discoveryResult.rssi != 0) {
                                  subtitle += ' | RSSI: ${discoveryResult.rssi}';
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
                                    subtitle: Text(subtitle),
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
                              "Press 'Scan for Devices' to list sensors nearby. Ensure your sensor is powered on and discoverable.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 30),
                            BluetoothTroubleshootingWidget(
                              onScanPressed: _startDiscovery,
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