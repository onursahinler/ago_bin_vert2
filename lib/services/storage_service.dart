import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _connectedDevicesKey = 'connected_bluetooth_devices';
  
  // Save a connected device to history
  static Future<void> saveConnectedDevice(String deviceId, String deviceName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devices = await getConnectedDevices();
      
      // Check if device already exists
      final existingIndex = devices.indexWhere((device) => device['id'] == deviceId);
      
      if (existingIndex != -1) {
        // Update existing device
        devices[existingIndex] = {
          'id': deviceId,
          'name': deviceName,
          'lastConnected': DateTime.now().toIso8601String(),
        };
      } else {
        // Add new device
        devices.add({
          'id': deviceId,
          'name': deviceName,
          'lastConnected': DateTime.now().toIso8601String(),
        });
      }
      
      // Keep only the last 5 devices
      if (devices.length > 5) {
        devices.sort((a, b) => DateTime.parse(b['lastConnected']!)
            .compareTo(DateTime.parse(a['lastConnected']!)));
        devices.removeRange(5, devices.length);
      }
      
      await prefs.setString(_connectedDevicesKey, jsonEncode(devices));
    } catch (e) {
      print('Error saving connected device: $e');
    }
  }
  
  // Get list of previously connected devices
  static Future<List<Map<String, String>>> getConnectedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? deviceJson = prefs.getString(_connectedDevicesKey);
      
      if (deviceJson == null || deviceJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> decodedDevices = jsonDecode(deviceJson);
      
      return decodedDevices
          .map((device) => {
                'id': device['id'] as String,
                'name': device['name'] as String,
                'lastConnected': device['lastConnected'] as String,
              })
          .toList();
    } catch (e) {
      print('Error getting connected devices: $e');
      return [];
    }
  }
  
  // Clear connection history
  static Future<void> clearConnectionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_connectedDevicesKey);
    } catch (e) {
      print('Error clearing connection history: $e');
    }
  }
}
