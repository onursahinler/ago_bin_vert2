import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Drawer(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF77BA69)),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drawer header with close button
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Color(0xFF77BA69), size: 30),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Menu items
              _buildMenuItem(
                  context: context,
                  icon: Icons.arrow_forward_ios,
                  title: 'List of Trash Bins',
                  route: '/trash_bins'
              ),
              SizedBox(height: 20),
              _buildMenuItem(
                  context: context,
                  icon: Icons.arrow_forward_ios,
                  title: 'Map View of Trash Bins',
                  route: '/map_view'
              ),
              SizedBox(height: 20),
              _buildMenuItem(
                  context: context,
                  icon: Icons.arrow_forward_ios,
                  title: 'Notifications',
                  route: '/notifications'
              ),
              SizedBox(height: 20),
              _buildMenuItem(
                  context: context,
                  icon: Icons.arrow_forward_ios,
                  title: 'Settings',
                  route: '/settings'
              ),
              SizedBox(height: 20),
              _buildMenuItem(
                  context: context,
                  icon: Icons.arrow_forward_ios,
                  title: 'Bluetooth Logs',
                  route: '/bluetooth_logs'
              ),
              Spacer(),
              // App name at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Text(
                  'AGO BinVert',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF77BA69),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF77BA69)),
            SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF77BA69),
              ),
            ),
          ],
        ),
      ),
    );
  }
}