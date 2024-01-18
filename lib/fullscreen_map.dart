import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

// Define default coordinates
double conservifyLat = 34.0312492;
double conservifyLong = -118.269107;
double accuracyDefault = 20.0;

class FullscreenMap extends StatefulWidget {
  final LatLng initialLocation;

  const FullscreenMap({super.key, required this.initialLocation});

  @override
  State<FullscreenMap> createState() => _FullscreenMapState();
}

class _FullscreenMapState extends State<FullscreenMap> {
  MapController mapController = MapController();
  LatLng? _userLocation;
  double? _userLocationAccuracy;

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
        _userLocationAccuracy = currentLocation.accuracy;
      });

      mapController.move(_userLocation!, 12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: _userLocation ?? widget.initialLocation,
              zoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.fieldkit.app',
              ),
              LocationMarkerLayer(
                  position: _userLocation != null
                      ? LocationMarkerPosition(
                          latitude: _userLocation!.latitude,
                          longitude: _userLocation!.longitude,
                          accuracy: _userLocationAccuracy ?? accuracyDefault)
                      : LocationMarkerPosition(
                          latitude: conservifyLat,
                          longitude: conservifyLong,
                          accuracy: accuracyDefault)),
            ],
          ),
          Positioned(
            top: 12.0,
            right: 12.0,
            child: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.close,
                  color: Colors.grey,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          )
        ],
      ),
    );
  }
}
