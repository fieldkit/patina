import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FullscreenMap extends StatefulWidget {
  final LatLng initialLocation;

  const FullscreenMap({super.key, required this.initialLocation});

  @override
  _FullscreenMapState createState() => _FullscreenMapState();
}

class _FullscreenMapState extends State<FullscreenMap> {
  MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: widget.initialLocation,
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
                Navigator.of(context).pop(); // Go back to previous screen
              },
            ),
          )
        ],
      ),
    );
  }
}
