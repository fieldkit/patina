import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:async/async.dart';

import 'diagnostics.dart';

class Location {}

Stream<Location> _monitorLocation() async* {
  yield Location();

  if (Platform.isLinux) {
    return;
  }

  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  final serviceStatusStream =
      StreamGroup.merge([Geolocator.getServiceStatusStream()]);
  serviceStatusStream.listen((ServiceStatus status) async {
    Loggers.ui.i("location: $status");
    if (status == ServiceStatus.enabled) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        Loggers.ui.i("location: requesting permission");
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Loggers.ui.i("location: denid");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Loggers.ui.i("location: denied forever");
        return;
      }

      final positionStream =
          Geolocator.getPositionStream(locationSettings: locationSettings);
      positionStream.listen((Position position) async {
        Loggers.ui.i("location: ${position.timestamp} ${position.accuracy}");
      });
    }
  });
}

class RequestLocationPermissions extends StatelessWidget {
  final Widget child;

  const RequestLocationPermissions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<Location>(
        builder: (context, Location location, otherChild) {
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
      child: RequestLocationPermissions(child: child),
    );
  }
}
