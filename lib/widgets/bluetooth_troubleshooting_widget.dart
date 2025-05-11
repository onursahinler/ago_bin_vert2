import 'package:flutter/material.dart';

class BluetoothTroubleshootingWidget extends StatelessWidget {
  final VoidCallback onScanPressed;
  
  const BluetoothTroubleshootingWidget({
    Key? key,
    required this.onScanPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Connection Troubleshooting',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildTroubleshootingStep(
            '1',
            'Make sure your HC-05 sensor is powered on and its LED is blinking or solid.',
          ),
          _buildTroubleshootingStep(
            '2',
            'HC-05 default PIN is usually "1234" or "0000". Make sure it\'s paired in system settings.',
          ),
          _buildTroubleshootingStep(
            '3',
            'HC-05 should be within 10 meters of your phone for reliable connection.',
          ),
          _buildTroubleshootingStep(
            '4',
            'Try resetting the HC-05 by powering it off and on.',
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onScanPressed,
            icon: Icon(Icons.bluetooth_searching),
            label: Text('Scan Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTroubleshootingStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
