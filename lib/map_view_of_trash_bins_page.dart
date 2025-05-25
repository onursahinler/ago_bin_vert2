import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'custom_drawer.dart';
import 'profile_page.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({Key? key}) : super(key: key);

  @override
  _MapViewPageState createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  static const Color _accent = Color(0xFF77BA69);
  late GoogleMapController _mapController;
  MapType _currentMapType = MapType.normal;

  final List<LatLng> _trashBinCoords = [
    LatLng(38.329706, 26.746472), //Trash Bin 1
    LatLng(38.429183, 27.134543), //Trash Bin 2
    LatLng(38.436155, 27.197548), //Trash Bin 3
  ];

  Set<Marker> get _markers => _trashBinCoords
      .asMap()
      .entries
      .map((e) => Marker(
    markerId: MarkerId('bin_${e.key}'),
    position: e.value,
    infoWindow: InfoWindow(title: 'Trash Bin ${e.key + 1}'),
  ))
      .toSet();

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
        actions:[
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
                  'Map View of Trash Bins',
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
              padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    GoogleMap(
                      mapType: _currentMapType,
                      initialCameraPosition: CameraPosition(
                        target: _trashBinCoords.first,
                        zoom: 15,
                      ),
                      markers: _markers,
                      onMapCreated: (c) => _mapController = c,
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () {
                          setState(() {
                            _currentMapType = _currentMapType ==
                                MapType.normal
                                ? MapType.satellite
                                : MapType.normal;
                          });
                        },
                        child: Icon(
                          _currentMapType == MapType.normal
                              ? Icons.satellite
                              : Icons.map,
                          color: _accent,
                        ),
                      ),
                    ),
                  ],
                ),
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
}
