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
  List<ScanResult> _scanResults = [];
  List<Map<String, String>> _previousDevices = [];
  bool _isConnected = false;
  String _statusText = 'Not connected';
  List<BluetoothDevice> _knownDevices = [];
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadPreviousDevices();
    
    // Check if already connected
    final manager = Provider.of<BluetoothManager>(context, listen: false);
    setState(() {
      _isConnected = manager.isConnected;
      if (_isConnected) {
        _statusText = manager.connectionStatus;
      }
    });
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
  
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults = [];
      _statusText = 'Scanning...';
    });
    
    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 15),
      );
      
      FlutterBluePlus.scanResults.listen((results) {
        // Filter for HC-05 and other potential Bluetooth modules
        final filteredResults = results.where((result) {
          final deviceName = result.device.name; // Store device name
          final name = deviceName?.toLowerCase() ?? ""; // Safely get lowercase name or empty string if null

          // Include devices if:
          // 1. Name contains target keywords
          // 2. Name is null or empty, but the device has an ID (to catch unnamed devices)
          return name.contains('hc-05') || 
                 name.contains('hc05') || 
                 name.contains('bt') || 
                 name.contains('arduino') ||
                 ((deviceName == null || deviceName.isEmpty) && result.device.id.toString().isNotEmpty); 
        }).toList();
        
        setState(() {
          _scanResults = filteredResults;
        });
      });
      
      // Stop scan after 15 seconds
      await Future.delayed(Duration(seconds: 15));
      await FlutterBluePlus.stopScan();
      
      setState(() {
        _isScanning = false;
        if (_scanResults.isEmpty) {
          _statusText = 'No HC-05 devices found';
        } else {
          _statusText = 'Found ${_scanResults.length} devices';
        }
      });
    } catch (e) {
      print('Error scanning: $e');
      setState(() {
        _isScanning = false;
        _statusText = 'Error scanning: $e';
      });
    }
  }
  
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _statusText = 'Connecting to ${device.name ?? 'Unknown Device'}...';
    });
    
    final manager = Provider.of<BluetoothManager>(context, listen: false);
    bool success = await manager.connectToDevice(device);
    
    setState(() {
      _isConnected = success;
      if (success) {
        _statusText = 'Connected to ${device.name ?? 'Unknown Device'}';
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
      await _getKnownDevices();
      BluetoothDevice? targetDevice;
      
      for (var device in _knownDevices) {
        if (device.id.toString() == deviceId) {
          targetDevice = device;
          break;
        }
      }
      
      if (targetDevice != null) {
        final manager = Provider.of<BluetoothManager>(context, listen: false);
        bool success = await manager.connectToDevice(targetDevice);
        
        setState(() {
          _isConnected = success;
          if (success) {
            _statusText = 'Connected to ${targetDevice?.name ?? "Unknown Device"}';
          } else {
            _statusText = 'Connection failed';
          }
        });
      } else {
        setState(() {
          _statusText = 'Device not found. Try scanning.';
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
  
  Future<void> _getKnownDevices() async {
    List<BluetoothDevice> devices = await FlutterBluePlus.systemDevices([]);
    setState(() {
      _knownDevices = devices;
    });
  }
  
  void _createTestBin() {
    final manager = Provider.of<BluetoothManager>(context, listen: false);
    
    // Generate random fill level between 10% and 95%
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
                              onPressed: _isScanning ? null : _startScan,
                              icon: Icon(Icons.bluetooth_searching),
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
                  // Show previously connected devices if we're not already connected
                  if (_previousDevices.isNotEmpty && !_isConnected)
                    PreviousDevicesWidget(
                      previousDevices: _previousDevices,
                      onConnectPressed: _connectToPreviousDevice,
                      isConnected: _isConnected,
                    ),
                  
                  // Show scan results if we have any
                  if (_scanResults.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Devices',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF77BA69),
                            ),
                          ),                          SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF77BA69).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _scanResults.length,
                              itemBuilder: (context, index) {
                                final result = _scanResults[index];
                                final device = result.device;
                                final name = device.name.isNotEmpty
                                    ? device.name
                                    : 'Unknown device (${device.id})';
                                
                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text('RSSI: ${result.rssi} dBm'),
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
                  // Show loading or empty state
                  else if (_isScanning)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF77BA69),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Scanning for devices...'),
                        ],
                      ),                      )
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
                                'Press the scan button to find nearby HC-05 devices',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 30),
                              BluetoothTroubleshootingWidget(
                                onScanPressed: _startScan,
                              ),
                            ],
                          ),
                        ),
                      )
                ],
              ),
            ),
          ),
          // Bottom slogan
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