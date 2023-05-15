import 'package:flutter/material.dart';

import 'gen/ffi.dart';

import 'app_state.dart';

class ViewStationRoute extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const ViewStationRoute({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Back'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
