import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:async/async.dart';

class Location {}

Stream<Location> _monitorLocation() async* {
  yield Location();

  if (Platform.isLinux) {
    return;
  }

  /*
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  // final initialStatus = Stream.value(await Geolocator.isLocationServiceEnabled() ? ServiceStatus.enabled : ServiceStatus.disabled);
  final serviceStatusStream = StreamGroup.merge([Geolocator.getServiceStatusStream()]);
  serviceStatusStream.listen((ServiceStatus status) async {
    debugPrint("location: $status");
    if (status == ServiceStatus.enabled) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("location: requesting permission");
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("location: denid");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("location: denied forever");
        return;
      }

      final positionStream = Geolocator.getPositionStream(locationSettings: locationSettings);
      positionStream.listen((Position position) async {
        debugPrint("location: $position");
      });
    }
  });
  */
}

class RequestLocationPermissions extends StatelessWidget {
  final Widget child;

  const RequestLocationPermissions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<Location>(builder: (context, Location location, otherChild) {
      return child;
    });
  }
}

class ProvideLocation extends StatelessWidget {
  final Widget child;

  const ProvideLocation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<Location>(
      create: (_) => _monitorLocation(),
      initialData: Location(),
      // catchError: (_, error) => error.toString(),
      child: RequestLocationPermissions(child: child),
    );
  }
}
