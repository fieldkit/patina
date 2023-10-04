import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <- Import this for SystemChrome
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  LatLng? _userLocation;
  MapController mapController = MapController();
  bool _isFullscreen = false; // <- Add this

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // Toggle fullscreen
  void _toggleFullscreen() {
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  Future<void> _getUserLocation() async {
    final location = Location();
    var hasPermission = await location.hasPermission();

    if (hasPermission == PermissionStatus.denied) {
      hasPermission = await location.requestPermission();
    }

    if (hasPermission == PermissionStatus.granted) {
      final currentLocation = await location.getLocation();
      setState(() {
        _userLocation =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });

      mapController.move(_userLocation!, 12);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            center: _userLocation ?? LatLng(34.0312492, -118.269107),
            zoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'org.fieldkit.app',
            ),
          ],
        ),
        Positioned(
          bottom: 12.0,
          right: 12.0,
          child: IconButton(
            iconSize: 36.0,
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.grey,
                size: 28.0,
              ),
            ),
            onPressed: _toggleFullscreen,
          ),
        )
      ],
    );
  }
}
