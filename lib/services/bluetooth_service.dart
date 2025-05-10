import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart' as fb;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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
  final fb.FlutterBluetoothSerial _bluetooth = fb.FlutterBluetoothSerial.instance;
  fb.BluetoothDevice? _device;
  fb.BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _dataSubscription;

  bool _isConnected = false;
  bool _isReconnecting = false;
  DateTime? _lastDataReceived;
  int _reconnectAttempts = 0;
  Timer? _connectionWatchdog;

  TrashBin? _sensorTrashBin;
  String _connectionStatus = 'Not connected';

  TrashBin? get sensorTrashBin => _sensorTrashBin;
  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;
  fb.BluetoothDevice? get connectedDevice => _device;
  String get connectionStatus => _connectionStatus;
  DateTime? get lastDataReceived => _lastDataReceived;

  Future<bool> connectToDevice(fb.BluetoothDevice device) async {
    if (_isConnected && _connection?.isConnected == true && _device?.address == device.address) {
      _setConnectionStatus('Already connected to ${device.name ?? device.address}');
      return true;
    }
    if (_isConnected) {
      await disconnect(silent: true);
    }

    _setConnectionStatus('Connecting to ${device.name ?? device.address}...');
    _isReconnecting = false;
    _reconnectAttempts = 0;

    try {
      print('Attempting to connect to ${device.address} using BluetoothManager');

      // Fix: Use BluetoothConnection.toAddress to get the connection object
      _connection = await fb.BluetoothConnection.toAddress(device.address);
      print('Connection successful to ${device.address}');

      await StorageService.saveConnectedDevice(
        device.address,
        device.name ?? "Unknown Device"
      );

      _device = device;
      _isConnected = true;
      _setConnectionStatus('Connected to ${device.name ?? device.address}');

      _dataSubscription = _connection?.input?.listen(_onDataReceived,
          onDone: () {
            _setConnectionStatus("Disconnected by remote peer");
            _handleDisconnection();
          },
          onError: (error) {
            _setConnectionStatus("Receive error: $error");
            _handleDisconnection();
          });

      _startConnectionWatchdog();
      notifyListeners();
      return true;
    } catch (e) {
      _setConnectionStatus('Error connecting: $e');
      _isConnected = false;
      _connection = null;
      _device = null;
      notifyListeners();
      return false;
    }
  }

  void _startConnectionWatchdog() {
    _connectionWatchdog?.cancel();
    _connectionWatchdog = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected && _lastDataReceived != null) {
        if (DateTime.now().difference(_lastDataReceived!).inSeconds > 60) {
          print('No data received for 60 seconds, attempting reconnect');
          _attemptReconnect();
        }
      } else if (_isConnected && _lastDataReceived == null && _connection?.isConnected == true) {
        print("Connected but no data received yet.");
      } else if (!_isConnected && !_isReconnecting) {
        _connectionWatchdog?.cancel();
      }
    });
  }

  void _handleDisconnection() {
    _isConnected = false;
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _connectionWatchdog?.cancel();
    _connection = null;
    if (!_isReconnecting) {
      _setConnectionStatus('Disconnected');
    }
    notifyListeners();
  }

  Future<void> _attemptReconnect() async {
    if (_isReconnecting || _reconnectAttempts >= 3 || _device == null) {
      if (_reconnectAttempts >= 3) _setConnectionStatus("Max reconnect attempts reached.");
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;
    _setConnectionStatus('Connection lost. Attempting reconnect (${_reconnectAttempts}/3) to ${_device?.name ?? _device?.address}...');
    notifyListeners();

    await disconnect(silent: true);
    await Future.delayed(Duration(seconds: 2));

    if (_device != null) {
      bool success = await connectToDevice(_device!);
      if (success) {
        _reconnectAttempts = 0;
        _setConnectionStatus('Reconnected successfully to ${_device?.name ?? _device?.address}');
      } else {
        _setConnectionStatus('Reconnect attempt ${_reconnectAttempts} failed for ${_device?.name ?? _device?.address}');
        if (_reconnectAttempts >= 3) {
          _setConnectionStatus("Failed to reconnect after 3 attempts.");
          _device = null;
        }
      }
    } else {
      _setConnectionStatus("Cannot reconnect, device information lost.");
    }

    _isReconnecting = false;
    notifyListeners();
  }

  void _setConnectionStatus(String status) {
    _connectionStatus = status;
    LogService.log(status, type: 'info');
    print("BluetoothManager Status: $status");
    notifyListeners();
  }

  Future<void> disconnect({bool silent = false}) async {
    if (!silent) {
      _setConnectionStatus('Disconnecting...');
    }

    _isReconnecting = false;
    _reconnectAttempts = 0;

    _dataSubscription?.cancel();
    _dataSubscription = null;
    _connectionWatchdog?.cancel();
    _connectionWatchdog = null;

    try {
      await _connection?.close();
    } catch (e) {
      if (!silent) _setConnectionStatus('Error during connection close: $e');
      print('Error during connection close: $e');
    } finally {
      _connection = null;
      _isConnected = false;
      if (!silent) {
        _setConnectionStatus('Disconnected');
      }
      notifyListeners();
    }
  }

  void _onDataReceived(Uint8List data) {
    _lastDataReceived = DateTime.now();
    try {
      final String message = utf8.decode(data);
      LogService.log('Received raw data: $message', type: 'debug');
      print('Received data: $message');

      RegExp regExp = RegExp(r'Fill\s*:\s*(\d+\.?\d*)\s*%');
      final match = regExp.firstMatch(message);

      if (match != null) {
        final fillLevelString = match.group(1);
        if (fillLevelString != null) {
          final fillLevel = double.tryParse(fillLevelString) ?? 0.0;
          final now = DateTime.now();
          final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

          _sensorTrashBin = TrashBin(
            id: 999,
            location: _device?.name ?? _device?.address ?? 'HC-05 Sensor',
            fillPercentage: fillLevel,
            lastUpdated: timeString,
          );

          LogService.log('Parsed fill level: ${fillLevel.toStringAsFixed(2)}%', type: 'info');
          _reconnectAttempts = 0;
          _setConnectionStatus('Data received. Fill: ${fillLevel.toStringAsFixed(2)}%');
        } else {
          LogService.log('Failed to parse fill level from: $message', type: 'warning');
        }
      } else {
        LogService.log('Received data does not match expected format: $message', type: 'warning');
      }
    } catch (e) {
      LogService.log('Error processing data: $e. Raw: ${String.fromCharCodes(data)}', type: 'error');
      print('Error processing data: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> sendData(String data) async {
    if (!_isConnected || _connection == null || _connection?.isConnected != true) {
      _setConnectionStatus('Cannot send data: Not connected.');
      return false;
    }

    try {
      Uint8List bytesToSend = Uint8List.fromList(utf8.encode(data + "\r\n"));
      _connection?.output.add(bytesToSend);
      await _connection?.output.allSent;
      LogService.log('Sent data: $data', type: 'info');
      return true;
    } catch (e) {
      _setConnectionStatus('Error sending data: $e');
      LogService.log('Error sending data: $e', type: 'error');
      return false;
    }
  }

  void createTestBin(double fillLevel) {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    String deviceLocation = 'Test HC-05 Sensor'; // Default
    if (_device != null) {
      // Use connected device's name if available, otherwise its address
      deviceLocation = _device!.name != null && _device!.name!.isNotEmpty ? _device!.name! : _device!.address;
    }

    _sensorTrashBin = TrashBin(
      id: 999,
      location: deviceLocation, // Use dynamic location
      fillPercentage: fillLevel,
      lastUpdated: timeString,
    );

    LogService.log('Created test bin data: ${deviceLocation} - Fill: ${fillLevel.toStringAsFixed(2)}%', type: 'info');
    notifyListeners();
  }

  Future<bool> tryConnectToPreviousDevice() async {
    final previousDeviceMaps = await StorageService.getConnectedDevices();
    if (previousDeviceMaps.isEmpty) {
      _setConnectionStatus("No previous devices found.");
      return false;
    }

    for (var deviceInfo in previousDeviceMaps) {
      final deviceName = deviceInfo['name'];
      final deviceAddress = deviceInfo['id'];

      if (deviceAddress == null) continue;

      _setConnectionStatus('Trying to connect to previously paired: ${deviceName ?? deviceAddress}...');
      notifyListeners();

      try {
        List<fb.BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();
        fb.BluetoothDevice? targetDevice;
        for (var bonded in bondedDevices) {
          if (bonded.address == deviceAddress) {
            targetDevice = bonded;
            break;
          }
        }
        targetDevice ??= fb.BluetoothDevice(address: deviceAddress, name: deviceName);

        final success = await connectToDevice(targetDevice);
        if (success) {
          return true;
        }
      } catch (e) {
        LogService.log('Error connecting to previous device $deviceAddress: $e', type: 'error');
        _setConnectionStatus('Failed to connect to $deviceAddress. Trying next...');
        continue;
      }
    }

    _setConnectionStatus("Couldn't connect to any previous devices.");
    return false;
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connectionWatchdog?.cancel();
    _connection?.close();
    super.dispose();
  }
}