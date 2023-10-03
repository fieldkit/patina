import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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

      mapController.move(_userLocation!, 12); // Zoom level 12 as in your code
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: _userLocation ??
            LatLng(34.0312492,
                -118.269107), // default to Conservify if location not yet retrieved
        zoom: 12,
      ),
      nonRotatedChildren: const [],
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'org.fieldkit.app',
        ),
      ],
    );
  }
}
