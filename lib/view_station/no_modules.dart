import 'package:fk/app_state.dart';
import 'package:fk/view_station/view_station_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fk/reader/screens.dart';

class NoModulesWidget extends StatelessWidget {
  final StationModel station;

  const NoModulesWidget({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'resources/images/Icon_Warning_error.png',
                  width: 48,
                  height: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.noModulesTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.noModulesMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MultiScreenFlow(
                          screenNames: const [
                            'no_modules.01',
                            'no_modules.02',
                            'no_modules.03',
                            'no_modules.04',
                          ],
                          onComplete: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ViewStationRoute(deviceId: station.deviceId),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: Text(localizations.addModulesButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
