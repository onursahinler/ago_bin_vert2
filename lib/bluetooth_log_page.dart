import 'package:flutter/material.dart';
import 'services/log_service.dart';
import 'custom_drawer.dart';

class BluetoothLogPage extends StatefulWidget {
  @override
  _BluetoothLogPageState createState() => _BluetoothLogPageState();
}

class _BluetoothLogPageState extends State<BluetoothLogPage> {
  List<LogEntry> _logEntries = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadLogs();
  }
  
  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });
    
    final entries = await LogService.getLogEntries();
    
    setState(() {
      _logEntries = entries;
      _isLoading = false;
    });
  }
  
  Future<void> _clearLogs() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Logs'),
        content: Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await LogService.clearLog();
              Navigator.pop(context);
              await _loadLogs();
            },
            child: Text('CLEAR'),
          ),
        ],
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Color(0xFF77BA69),
            ),
            onPressed: _loadLogs,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Color(0xFF77BA69),
            ),
            onPressed: _clearLogs,
          ),
        ],
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
                  'Bluetooth Logs',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF77BA69),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Connection and data logs for troubleshooting',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF77BA69),
                      ),
                    ),
                  )
                : _logEntries.isEmpty
                    ? Center(
                        child: Text(
                          'No logs available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logEntries.length,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemBuilder: (context, index) {
                          final entry = _logEntries[index];
                          return _buildLogEntry(entry);
                        },
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
  
  Widget _buildLogEntry(LogEntry entry) {
    Color color;
    IconData icon;
    
    switch (entry.type) {
      case 'error':
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning_amber_outlined;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info_outline;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: 8),
              Text(
                _formatTimestamp(entry.timestamp),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            entry.message,
            style: TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
