import 'package:flutter/material.dart';

class ConfigureSchedulePage extends StatelessWidget {
  const ConfigureSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [ScheduleWidget()]);
  }
}

class ScheduleWidget extends StatelessWidget {
  const ScheduleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleScheduleWidget();
  }
}

class SimpleScheduleWidget extends StatelessWidget {
  const SimpleScheduleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text("Schedule");
  }
}
