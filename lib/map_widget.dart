import 'package:fk/fullscreen_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Define default coordinates
var conservifyCoordinates = LatLng(34.0312492, -118.269107);

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  LatLng? _userLocation;
  double? _userLocationAccuracy;
  MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _navigateToFullscreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => FullscreenMap(
          initialLocation: _userLocation ?? conservifyCoordinates),
    ));
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.locationDenied)),
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
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              maxZoom: 19,
              userAgentPackageName: 'org.fieldkit.app',
            ),
            LocationMarkerLayer(
                position: _userLocation != null
                    ? LocationMarkerPosition(
                        latitude: _userLocation!.latitude,
                        longitude: _userLocation!.longitude,
                        accuracy: _userLocationAccuracy ??
                            20.0 // If the accuracy is null, we'll default to 20.0 meters.
                        )
                    : LocationMarkerPosition(
                        latitude: 34.0312492,
                        longitude: -118.269107,
                        accuracy: 20.0)),
          ],
        ),
        Positioned(
          top: 12.0,
          right: 12.0,
          child: IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.fullscreen,
                color: Colors.grey,
              ),
            ),
            onPressed: _navigateToFullscreen,
          ),
        )
      ],
    );
  }
}
