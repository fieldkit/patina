import 'package:flutter/material.dart';

import 'app_state.dart';

class ViewStationRoute extends StatelessWidget {
  const ViewStationRoute({super.key, required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(station.name ?? "..."),
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
