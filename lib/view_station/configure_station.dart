import 'package:fk/constants.dart';
import 'package:fk/providers.dart';
import 'package:fk/view_station/station_modules_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../gen/api.dart';
import '../unknown_station_page.dart';

import 'configure_lora.dart';
import 'configure_wifi_networks.dart';
import 'firmware_page.dart';
import 'station_events.dart';

class ConfigureStationRoute extends StatelessWidget {
  final String deviceId;

  const ConfigureStationRoute({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Consumer<KnownStationsModel>(
      builder: (context, knownStations, child) {
        var station = knownStations.find(deviceId);
        if (station == null) {
          return const NoSuchStationPage();
        } else {
          return StationProviders(
              deviceId: deviceId,
              child: ConfigureStationPage(station: station));
        }
      },
    );
  }
}

class NameConfigWidget extends StatefulWidget {
  final StationModel station;

  const NameConfigWidget({super.key, required this.station});

  @override
  // ignore: library_private_types_in_public_api
  _NameConfigWidgetState createState() => _NameConfigWidgetState();
}

class _NameConfigWidgetState extends State<NameConfigWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.station.config!.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitName(String value) async {
    var newName = NameConfig(name: value);
    OverlayEntry overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(overlayEntry);

    try {
      await configureName(deviceId: widget.station.deviceId, config: newName);
      _showSuccessMessage();
    } catch (error) {
      _showErrorMessage(error.toString());
    } finally {
      overlayEntry.remove();
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.nameConfigSuccess),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.errorMessage(message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.settingsNameHint,
                    hintText: AppLocalizations.of(context)!.settingsNameHint,
                  ),
                  controller: _controller,
                  enabled: widget.station.connected,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: widget.station.connected
                      ? AppColors.primaryColor
                      : Colors.grey.shade300,
                ),
                onPressed: widget.station.connected
                    ? () {
                        var inputText = _controller.text;
                        if (inputText.trim().isEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!.error),
                              content: Text(AppLocalizations.of(context)!
                                  .nameErrorDescription),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(AppLocalizations.of(context)!.ok),
                                ),
                              ],
                            ),
                          );
                        } else if (!isValidName(inputText)) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!.error),
                              content: Text(AppLocalizations.of(context)!
                                  .nameErrorDescription),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(AppLocalizations.of(context)!.ok),
                                ),
                              ],
                            ),
                          );
                        } else {
                          _submitName(inputText);
                        }
                      }
                    : null,
                child: Text(AppLocalizations.of(context)!.submit,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool isValidName(String name) {
  final RegExp validName = RegExp(r'^[a-zA-Z0-9_áéíóúÁÉÍÓÚñÑüÜ ]+$');
  return validName.hasMatch(name);
}

class ConfigureStationPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const ConfigureStationPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(AppLocalizations.of(context)!.settingsTitle),
            Text(
              config.name,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          NameConfigWidget(station: station),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsWifi),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationProviders(
                      deviceId: station.deviceId,
                      child: ConfigureWiFiPage(
                        station: station,
                      )),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsLora),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationProviders(
                      deviceId: station.deviceId,
                      child: const ConfigureLoraPage()),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsFirmware),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationProviders(
                      deviceId: station.deviceId,
                      child: StationFirmwarePage(
                        station: station,
                      )),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsModules),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationProviders(
                      deviceId: station.deviceId,
                      child: StationModulesPage(
                        station: station,
                      )),
                ),
              );
            },
          ),
          const Divider(),
          /*
          ListTile(
            title: Text(AppLocalizations.of(context)!.endDeployment),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.forgetStation),
            onTap: () {},
          ),
          const Divider(),
          */
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsEvents),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationProviders(
                      deviceId: station.deviceId,
                      child: const ViewStationEventsPage()),
                ),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
