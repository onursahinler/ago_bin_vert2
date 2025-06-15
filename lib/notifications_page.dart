import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'custom_drawer.dart';
import 'services/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final dynamicNotifications = context.watch<NotificationService>().notifications;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationService>(context, listen: false).markAllAsRead();
    });

    final staticNotifications = [
      NotificationItem(
        statusColor: Colors.red,
        title: 'Trash Bin 3',
        message: 'is nearly Full !!',
        timestamp: DateTime.now().subtract(Duration(minutes: 15)),
      ),
      NotificationItem(
        statusColor: Colors.green,
        title: 'Trash Bin 2',
        message: 'has been Emptied',
        timestamp: DateTime.now().subtract(Duration(minutes: 45)),
      ),
      NotificationItem(
        statusColor: Colors.amber,
        title: 'Trash Bin 1',
        message: 'is %50 Full',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
      ),
    ];

    // Dinamik + sabit birleştir
    final allNotifications = [...dynamicNotifications, ...staticNotifications];

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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                backgroundColor: Color(0xFFE0F0E0),
                child: Icon(
                  Icons.person,
                  color: Color(0xFF77BA69),
                ),
              ),
            ),
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
                  'Notifications',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF77BA69),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: allNotifications.isEmpty
                  ? Center(
                child: Text(
                  'No notifications yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: allNotifications.length,
                itemBuilder: (context, index) {
                  final notif = allNotifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildNotificationItem(
                      statusColor: notif.statusColor,
                      title: notif.title,
                      message: notif.message,
                      timeAgo: notif.timeAgo,
                      read: false,
                    ),
                  );
                },
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

  Widget _buildNotificationItem({
    required Color statusColor,
    required String title,
    required String message,
    required String timeAgo,
    required bool read,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF77BA69)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}