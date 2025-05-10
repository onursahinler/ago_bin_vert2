import 'package:flutter/material.dart';

class PreviousDevicesWidget extends StatelessWidget {
  final List<Map<String, String>> previousDevices;
  final Function(String) onConnectPressed;
  final bool isConnected;
  
  const PreviousDevicesWidget({
    Key? key,
    required this.previousDevices,
    required this.onConnectPressed,
    required this.isConnected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (previousDevices.isEmpty) {
      return Container();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
          child: Text(
            'Previously Connected Devices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF77BA69),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.0),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF77BA69).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: previousDevices.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final device = previousDevices[index];
              // Format last connected date
              String formattedDate = 'Unknown';
              try {
                final lastConnected = DateTime.parse(device['lastConnected'] ?? '');
                final now = DateTime.now();
                final difference = now.difference(lastConnected);
                
                if (difference.inMinutes < 1) {
                  formattedDate = 'Just now';
                } else if (difference.inHours < 1) {
                  formattedDate = '${difference.inMinutes} minutes ago';
                } else if (difference.inDays < 1) {
                  formattedDate = '${difference.inHours} hours ago';
                } else if (difference.inDays < 30) {
                  formattedDate = '${difference.inDays} days ago';
                } else {
                  formattedDate = '${lastConnected.day}/${lastConnected.month}/${lastConnected.year}';
                }
              } catch (e) {
                print('Error parsing date: $e');
              }
              
              return ListTile(
                leading: Icon(
                  Icons.bluetooth,
                  color: Color(0xFF77BA69),
                ),
                title: Text(
                  device['name'] ?? 'Unknown Device',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('Last connected: $formattedDate'),
                trailing: TextButton(
                  onPressed: isConnected ? null : () => onConnectPressed(device['id']!),
                  child: Text('Connect'),
                  style: TextButton.styleFrom(
                    foregroundColor: isConnected ? Colors.grey : Color(0xFF77BA69),
                  ),
                ),
                onTap: isConnected ? null : () => onConnectPressed(device['id']!),
              );
            },
          ),
        ),
      ],
    );
  }
}
