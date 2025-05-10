import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'storage_service.dart';
import 'log_service.dart';

class TrashBin {
  final int id;
  final String location;
  final double fillPercentage;
  final String lastUpdated;

  Color get statusColor {
    if (fillPercentage < 50) {
      return Colors.green;
    } else if (fillPercentage < 80) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  TrashBin({
    required this.id,
    required this.location,
    required this.fillPercentage,
    required this.lastUpdated,
  });
}

class BluetoothManager extends ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _subscription;
  bool _isConnected = false;
  bool _isReconnecting = false;
  DateTime? _lastDataReceived;
  int _reconnectAttempts = 0;
  Timer? _connectionWatchdog;
  
  // Trash bin data from the sensor
  TrashBin? _sensorTrashBin;
  String _connectionStatus = 'Not connected';
  
  // Getters
  TrashBin? get sensorTrashBin => _sensorTrashBin;
  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;
  BluetoothDevice? get connectedDevice => _device;
  String get connectionStatus => _connectionStatus;
  DateTime? get lastDataReceived => _lastDataReceived;
  
  // Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _setConnectionStatus('Connecting to ${device.name}...');
      _isReconnecting = false;
      _reconnectAttempts = 0;
      
      await device.connect(timeout: Duration(seconds: 10));
      _device = device;
      _isConnected = true;
      _setConnectionStatus('Connected to ${device.name}');
      
      // Save the connected device to history
      await StorageService.saveConnectedDevice(
        device.id.toString(),
        device.name.isNotEmpty ? device.name : "Unknown HC-05 Device"
      );
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // Find the UART service on HC-05 (standard SPP UUID)
      bool foundService = false;
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          // Look for a characteristic that can notify us
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            _characteristic = characteristic;
            await _characteristic!.setNotifyValue(true);
            
            // Subscribe to notifications
            _subscription = _characteristic!.lastValueStream.listen(_onDataReceived);
            foundService = true;
            break;
          }
        }
        if (foundService) break;
      }
      
      if (!foundService) {
        _setConnectionStatus('Could not find proper characteristic for data transfer');
        return false;
      }
      
      // Start the connection watchdog
      _startConnectionWatchdog();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setConnectionStatus('Error connecting: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }
  
  // Start a timer to check for connection issues
  void _startConnectionWatchdog() {
    _connectionWatchdog?.cancel();
    _connectionWatchdog = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected && _lastDataReceived != null) {
        // Check if we haven't received data for more than 60 seconds
        if (DateTime.now().difference(_lastDataReceived!).inSeconds > 60) {
          print('No data received for 60 seconds, attempting reconnect');
          _attemptReconnect();
        }
      }
    });
  }
  
  // Attempt to reconnect to the device
  Future<void> _attemptReconnect() async {
    if (_isReconnecting || _reconnectAttempts > 3 || _device == null) return;
    
    _isReconnecting = true;
    _reconnectAttempts++;
    _setConnectionStatus('Connection lost. Attempting reconnect (${_reconnectAttempts}/3)...');
    notifyListeners();
    
    try {
      await disconnect(silent: true);
      await Future.delayed(Duration(seconds: 2));
      bool success = await connectToDevice(_device!);
      if (success) {
        _reconnectAttempts = 0;
        _setConnectionStatus('Reconnected successfully');
      } else {
        _setConnectionStatus('Reconnect attempt failed');
      }
    } catch (e) {
      _setConnectionStatus('Reconnect error: $e');
    } finally {
      _isReconnecting = false;
      notifyListeners();
    }
  }
  
  // Set connection status with timestamp
  void _setConnectionStatus(String status) {
    _connectionStatus = status;
    LogService.log(status, type: 'info');
    notifyListeners();
  }
  
  // Disconnect from device
  Future<void> disconnect({bool silent = false}) async {
    if (_device != null) {
      try {
        if (!silent) {
          _setConnectionStatus('Disconnecting...');
        }
        
        _subscription?.cancel();
        _connectionWatchdog?.cancel();
        
        await _device!.disconnect();
        _device = null;
        _characteristic = null;
        _isConnected = false;
        
        if (!silent) {
          _setConnectionStatus('Disconnected');
        }
        
        notifyListeners();
      } catch (e) {
        _setConnectionStatus('Error disconnecting: $e');
      }
    }
  }
  
  // Process data received from the HC-05
  void _onDataReceived(List<int> data) {
    try {
      // Update last data received timestamp
      _lastDataReceived = DateTime.now();
      
      // Convert bytes to string
      final String message = utf8.decode(data);
      print('Received data: $message');
      
      // Parse fill level (Format: "Fill : x.xx %")
      RegExp regExp = RegExp(r'Fill\s*:\s*(\d+\.\d+)\s*%');
      final match = regExp.firstMatch(message);
      
      if (match != null) {
        final fillLevel = double.parse(match.group(1) ?? '0.0');
        final now = DateTime.now();
        final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        // Create a trash bin with the data
        _sensorTrashBin = TrashBin(
          id: 999, // Special ID for sensor bin
          location: 'HC-05 Sensor',
          fillPercentage: fillLevel,
          lastUpdated: timeString,
        );
        
        // Log the received data
        LogService.log('Received fill level: ${fillLevel.toStringAsFixed(2)}%', type: 'info');
        
        // Reset reconnect attempts on successful data
        _reconnectAttempts = 0;
        
        // Notify listeners to update UI
        notifyListeners();
      }
    } catch (e) {
      print('Error processing data: $e');
    }
  }
  
  // Method to send data to the device
  Future<bool> sendData(String data) async {
    if (!_isConnected || _characteristic == null) {
      return false;
    }
    
    try {
      List<int> bytes = utf8.encode(data);
      await _characteristic!.write(bytes);
      return true;
    } catch (e) {
      print('Error sending data: $e');
      return false;
    }
  }
  
  // Method to manually create a test bin (for testing without actual connection)
  void createTestBin(double fillLevel) {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    _sensorTrashBin = TrashBin(
      id: 999,
      location: 'Test HC-05 Sensor',
      fillPercentage: fillLevel,
      lastUpdated: timeString,
    );
    
    notifyListeners();
  }
  
  // Method to try to connect to a previously connected device
  Future<bool> tryConnectToPreviousDevice() async {
    try {
      final previousDevices = await StorageService.getConnectedDevices();
      if (previousDevices.isEmpty) {
        return false;
      }
      
      // Try to connect to the most recently connected device first
      for (var deviceInfo in previousDevices) {
        _setConnectionStatus('Trying to connect to previously paired device: ${deviceInfo['name']}...');
        
        try {
          // Convert the ID string back to a DeviceIdentifier
          final deviceId = DeviceIdentifier(deviceInfo['id']!);
          final List<BluetoothDevice> knownDevices = await FlutterBluePlus.systemDevices([]);
          
          BluetoothDevice? matchingDevice;
          for (var device in knownDevices) {
            if (device.id == deviceId) {
              matchingDevice = device;
              break;
            }
          }
          
          if (matchingDevice != null) {
            final success = await connectToDevice(matchingDevice);
            if (success) {
              return true;
            }
          }
        } catch (e) {
          print('Error connecting to previous device: $e');
          continue; // Try the next device
        }
      }
      
      return false;
    } catch (e) {
      print('Error in tryConnectToPreviousDevice: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _connectionWatchdog?.cancel();
    super.dispose();
  }
}