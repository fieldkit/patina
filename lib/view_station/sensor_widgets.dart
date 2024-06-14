import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../gen/api.dart';
import '../meta.dart';

class DisplaySensorValue extends StatelessWidget {
  final SensorConfig sensor;
  final LocalizedSensor localized;
  final MainAxisSize mainAxisSize;
  final bool isConnected;

  const DisplaySensorValue({
    super.key,
    this.mainAxisSize = MainAxisSize.max,
    required this.sensor,
    required this.localized,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double valueSize = screenWidth < 360 ? 18 : 24;
    double unitsSize = screenWidth < 360 ? 10 : 12;

    final valueFormatter = NumberFormat("0.##");
    final valueStyle = TextStyle(
      fontSize: valueSize,
      color: Colors.black54,
      fontWeight: FontWeight.w500,
    );
    final unitsStyle = TextStyle(
      fontSize: unitsSize,
      color: isConnected ? const Color.fromRGBO(64, 64, 64, 1) : Colors.grey,
      fontWeight: FontWeight.normal,
    );
    final value = sensor.value?.value;
    final uom = localized.uom;

    // Determine the direction of the value change
    final previousValue = sensor.previousValue?.value;
    Widget changeIcon = const SizedBox.shrink();
    if (isConnected && previousValue != null && value != null) {
      if (value > previousValue) {
        // Value is rising
        changeIcon = const Icon(Icons.arrow_upward, color: Colors.blue);
      } else if (value < previousValue) {
        // Value is falling
        changeIcon = const Icon(Icons.arrow_downward, color: Colors.red);
      } else {
        // Value is unchanged, nothing
      }
    }

    String displayValue;
    String displayUom = uom;

    if (value == null) {
      final localizations = AppLocalizations.of(context)!;
      return Row(mainAxisSize: mainAxisSize, children: [
        Text("--", style: valueStyle),
        Container(
          padding: const EdgeInsets.only(left: 4),
          child: Text(uom, style: unitsStyle),
        ),
        if (!isConnected)
          Text(localizations.lastReadingLabel,
              style: TextStyle(fontSize: unitsSize, color: Colors.grey)),
      ]);
    }

    if (uom == 'ms') {
      final formattedMilliseconds = formatMilliseconds(value.toInt());
      displayValue = formattedMilliseconds['value']!;
      displayUom = formattedMilliseconds['uom']!;
    } else {
      displayValue = valueFormatter.format(value);
    }

    final suffix = Container(
      padding: const EdgeInsets.only(left: 4),
      child: Text(displayUom, style: unitsStyle),
    );

    return Row(mainAxisSize: mainAxisSize, children: [
      Text(displayValue, style: valueStyle),
      suffix,
      changeIcon,
    ]);
  }
}

class SensorInfo extends StatelessWidget {
  final SensorConfig sensor;
  final bool isConnected;

  const SensorInfo({
    super.key,
    required this.sensor,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final localized = LocalizedSensor.get(sensor, localizations);

    return Container(
        padding: const EdgeInsets.all(10),
        child: ColoredBox(
            color: const Color.fromRGBO(232, 232, 232, 1),
            child: Container(
                padding: const EdgeInsets.all(6),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DisplaySensorValue(
                            sensor: sensor,
                            localized: localized,
                            isConnected: isConnected,
                          )),
                      Text(localized.name)
                    ]))));
  }
}

class SensorsGrid extends StatelessWidget {
  final List<Widget> children;

  const SensorsGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double width = constraints.maxWidth;
      double boxSize = width < 240 ? width : (width / 2.0);

      return Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            alignment: WrapAlignment.start,
            children: children.map((child) {
              return SizedBox(
                width: boxSize,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: child,
                ),
              );
            }).toList(),
          ));
    });
  }
}

Map<String, String> formatMilliseconds(int milliseconds) {
  if (milliseconds < 1000) {
    return {'value': '$milliseconds', 'uom': 'ms'};
  } else if (milliseconds < 60000) {
    return {'value': (milliseconds / 1000).toStringAsFixed(0), 'uom': 'sec'};
  } else if (milliseconds < 3600000) {
    return {'value': (milliseconds / 60000).toStringAsFixed(0), 'uom': 'min'};
  } else if (milliseconds < 86400000) {
    return {'value': (milliseconds / 3600000).toStringAsFixed(0), 'uom': 'hr'};
  } else {
    return {
      'value': (milliseconds / 86400000).toStringAsFixed(0),
      'uom': 'days'
    };
  }
}
