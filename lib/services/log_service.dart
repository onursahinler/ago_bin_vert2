import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LogEntry {
  final DateTime timestamp;
  final String message;
  final String type; // 'info', 'warning', 'error'
  
  LogEntry({
    required this.timestamp,
    required this.message,
    required this.type,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'type': type,
    };
  }
  
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      message: json['message'],
      type: json['type'],
    );
  }
}

class LogService {
  static const String _logKey = 'bluetooth_log_entries';
  static const int _maxLogEntries = 100;
  
  static Future<void> log(String message, {String type = 'info'}) async {
    try {
      final entry = LogEntry(
        timestamp: DateTime.now(),
        message: message,
        type: type,
      );
      
      final entries = await getLogEntries();
      entries.insert(0, entry); // Add to beginning of list (newest first)
      
      // Trim log if too many entries
      if (entries.length > _maxLogEntries) {
        entries.removeRange(_maxLogEntries, entries.length);
      }
      
      await _saveEntries(entries);
      
      // Print to console as well
      print('${type.toUpperCase()}: $message');
    } catch (e) {
      print('Error logging message: $e');
    }
  }
  
  static Future<List<LogEntry>> getLogEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? entriesJson = prefs.getString(_logKey);
      
      if (entriesJson == null || entriesJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> decodedEntries = jsonDecode(entriesJson);
      
      return decodedEntries
          .map((entry) => LogEntry.fromJson(entry))
          .toList();
    } catch (e) {
      print('Error getting log entries: $e');
      return [];
    }
  }
  
  static Future<void> _saveEntries(List<LogEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = jsonEncode(entries.map((e) => e.toJson()).toList());
      await prefs.setString(_logKey, entriesJson);
    } catch (e) {
      print('Error saving log entries: $e');
    }
  }
  
  static Future<void> clearLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logKey);
    } catch (e) {
      print('Error clearing log: $e');
    }
  }
}
