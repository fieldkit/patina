import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fk/diagnostics.dart';
import 'package:flutter/material.dart';

class MonitorConnectionWidget extends StatefulWidget {
  final Widget child;

  const MonitorConnectionWidget({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => _MonitorConnectionWidget();
}

class _MonitorConnectionWidget extends State<MonitorConnectionWidget> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((event) {
      Loggers.state.i("connectivity: $event");
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
