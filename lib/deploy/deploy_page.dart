import 'package:fk/app_state.dart';
import 'package:fk/common_widgets.dart';
import 'package:fk/deploy/configure_schedule_page.dart';
import 'package:fk/diagnostics.dart';
import 'package:fk/gen/bridge_definitions.dart';
import 'package:fk/map_widget.dart';
import 'package:fk/providers.dart';
import 'package:fk/unknown_station_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

class DeployStationPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const DeployStationPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    const Widget map = SizedBox(height: 200, child: MapWidget());

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.deployTitle),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: Size.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 0),
                Text(config.name),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        body: ListView(
          children: [map, DeployFormWidget()],
        ));
  }
}

class DeployFormWidget extends StatefulWidget {
  const DeployFormWidget({super.key});

  @override
  State<DeployFormWidget> createState() => _DeployFormState();
}

class _DeployFormState extends State<DeployFormWidget> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return FormBuilder(
        key: _formKey,
        child: Column(
          children: [
            FormBuilderTextField(
              name: 'location',
              keyboardType: TextInputType.text,
              decoration:
                  InputDecoration(labelText: localizations.deployLocation),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            const ScheduleWidget(),
            ElevatedTextButton(
              onPressed: () async {
                if (_formKey.currentState!.saveAndValidate()) {
                  final values = _formKey.currentState!.value;
                  Loggers.ui.i("$values");
                  final String location = values["location"];
                  final int scheduleEvery = int.parse(values["scheduleEvery"]);
                  final UnitOfTime scheduleUnit = values["scheduleUnit"];
                  Loggers.ui.i("$location $scheduleEvery $scheduleUnit");
                }
              },
              text: localizations.deployButton,
            ),
          ]
              .map((child) =>
                  Padding(padding: const EdgeInsets.all(8), child: child))
              .toList(),
        ));
  }
}

class DeployStationRoute extends StatelessWidget {
  final String deviceId;

  const DeployStationRoute({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Consumer<KnownStationsModel>(
      builder: (context, knownStations, child) {
        var station = knownStations.find(deviceId);
        if (station == null) {
          return const NoSuchStationPage();
        } else {
          return StationProviders(
              deviceId: deviceId, child: DeployStationPage(station: station));
        }
      },
    );
  }
}
