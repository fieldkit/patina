import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

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
    return IntrinsicHeight(
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(0),
                child: FormBuilderTextField(
                  name: 'scheduleEvery',
                  initialValue: "10",
                  decoration: const InputDecoration(
                    labelText: "Every",
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.integer(),
                  ]),
                ))),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: FormBuilderDropdown<UnitOfTime>(
                  name: 'scheduleUnit',
                  initialValue: UnitOfTime.minutes,
                  items: const [
                    DropdownMenuItem<UnitOfTime>(
                      value: UnitOfTime.minutes,
                      child: Text("Minutes"),
                    ),
                    DropdownMenuItem<UnitOfTime>(
                      value: UnitOfTime.hours,
                      child: Text("Hours"),
                    ),
                  ],
                ))),
      ],
    ));
  }
}

enum UnitOfTime {
  minutes,
  hours,
}
