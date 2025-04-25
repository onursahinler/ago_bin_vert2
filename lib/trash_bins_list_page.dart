import 'package:flutter/material.dart';
import 'trash_bin_detail_page.dart';
import 'custom_drawer.dart';
import 'profile_page.dart';

class TrashBinsListPage extends StatelessWidget {
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
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
                  'List of Trash Bins',
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
              child: ListView(
                children: [
                  // Trash Bin #1
                  _buildTrashBinItem(
                    context: context,
                    number: 1,
                    location: 'Exit of Urla\nDevlet Hospital',
                    color: Colors.green,
                    fillPercentage: 45,
                    lastUpdated: '17:20',
                  ),
                  SizedBox(height: 15),

                  // Trash Bin #2
                  _buildTrashBinItem(
                    context: context,
                    number: 2,
                    location: 'Cumhuriyet\nSquare',
                    color: Colors.amber,
                    fillPercentage: 70,
                    lastUpdated: '17:10',
                  ),
                  SizedBox(height: 15),

                  // Trash Bin #3
                  _buildTrashBinItem(
                    context: context,
                    number: 3,
                    location: 'Atatürk Park',
                    color: Colors.red,
                    fillPercentage: 90,
                    lastUpdated: '17:35',
                  ),
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

  Widget _buildTrashBinItem({
    required BuildContext context,
    required int number,
    required String location,
    required Color color,
    required int fillPercentage,
    required String lastUpdated,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrashBinDetailPage(
              binNumber: number,
              location: location,
              statusColor: color,
              fillPercentage: fillPercentage,
              lastUpdated: lastUpdated,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF77BA69)),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              // Colored circle indicator
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 20),
              // Trash bin details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trash Bin #$number',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}