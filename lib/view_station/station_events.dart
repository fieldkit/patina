import 'package:fk/common_widgets.dart';
import 'package:fk/diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class ViewStationEventsPage extends StatelessWidget {
  const ViewStationEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StationConfiguration config = context.watch<StationConfiguration>();

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settingsTitle),
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
        body: ListView(children: const [EventsList()]));
  }
}

class EventsList extends StatelessWidget {
  const EventsList({super.key});

  Widget getEventWidget(Event event) {
    if (event is RestartEvent) {
      return RestartEventWidget(event: event);
    }
    if (event is LoraEvent) {
      return LoraEventWidget(event: event);
    }
    if (event is UnknownEvent) {
      return UnknownEventWidget(event: event);
    }
    return const OopsBug();
  }

  @override
  Widget build(BuildContext context) {
    final StationConfiguration stationConfig =
        context.watch<StationConfiguration>();
    Loggers.ui.i("Events ${stationConfig.events()}");

    return Column(
        children: WH.divideWith(
            () => const Divider(),
            stationConfig
                .events()
                .map((e) => WH.padColumn(getEventWidget(e)))
                .toList()));
  }
}

class LoraEventWidget extends StatelessWidget {
  final LoraEvent event;

  const LoraEventWidget({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:MM:SS');
    final localizations = AppLocalizations.of(context)!;
    return Column(children: [
      Text(localizations.eventLora, style: eventHeaderStyle()),
      WH.align(Text(localizations.eventTime, style: labelStyle())),
      WH.align(Text(formatter.format(event.time))),
      WH.align(Text(localizations.eventCode, style: labelStyle())),
      WH.align(Text(event.code.toString()))
    ]);
  }
}

class RestartEventWidget extends StatelessWidget {
  final RestartEvent event;

  const RestartEventWidget({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:MM:SS');
    final localizations = AppLocalizations.of(context)!;
    return Column(children: [
      Text(localizations.eventRestart, style: eventHeaderStyle()),
      WH.align(Text(localizations.eventTime, style: labelStyle())),
      WH.align(Text(formatter.format(event.time))),
      WH.align(Text(localizations.eventReason, style: labelStyle())),
      WH.align(Text(event.reason))
    ]);
  }
}

class UnknownEventWidget extends StatelessWidget {
  final UnknownEvent event;

  const UnknownEventWidget({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Text(localizations.eventUnknown, style: eventHeaderStyle());
  }
}

TextStyle labelStyle() {
  return const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
}

TextStyle eventHeaderStyle() {
  return const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
}
