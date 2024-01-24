import 'package:fk/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
import '../gen/ffi.dart';

class ConfigureWiFiPage extends StatelessWidget {
  final StationModel station;

  String get deviceId => station.deviceId;

  StationConfig get config => station.config!;

  const ConfigureWiFiPage({super.key, required this.station});

  Widget addNetworkOption(BuildContext context) {
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    return ElevatedButton(
        style: ButtonStyle(
          backgroundColor:
              MaterialStateProperty.all<Color>(AppColors.primaryColor),
          padding: MaterialStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0)),
        ),
        child: Text(
          "Add Network",
          style: WH.buttonStyle(18),
        ),
        onPressed: () async {
          final navigator = Navigator.of(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WifiNetworkForm(
                  onSave: (WifiNetwork network) async {
                    Loggers.ui.i("$deviceId adding network");

                    final overlay = context.loaderOverlay;
                    overlay.show();
                    try {
                      await configuration.addNetwork(deviceId,
                          station.ephemeral?.networks ?? List.empty(), network);
                    } catch (e) {
                      Loggers.ui.e("$deviceId $e");
                    } finally {
                      navigator.pop();
                      overlay.hide();
                    }
                  },
                  original:
                      WifiNetwork(ssid: "", password: "", preferred: false)),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    Loggers.ui.i("station ${station.ephemeral?.networks}");

    final List<WifiNetworkListItem> networks = station.ephemeral?.networks
            .where((network) => network.ssid.isNotEmpty)
            .map((network) => WifiNetworkListItem(
                network: network,
                onRemove: () async {
                  await showDialog(
                      context: context,
                      builder: (context) {
                        final localizations = AppLocalizations.of(context)!;
                        final navigator = Navigator.of(context);

                        return AlertDialog(
                          title:
                              Text(localizations.confirmClearCalibrationTitle),
                          content: Text(localizations.confirmDelete),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () {
                                  navigator.pop();
                                },
                                child: Text(localizations.confirmCancel)),
                            TextButton(
                                onPressed: () async {
                                  navigator.pop();

                                  Loggers.ui.i("$deviceId remove network");
                                  final overlay = context.loaderOverlay;
                                  overlay.show();
                                  try {
                                    await configuration.removeNetwork(
                                        deviceId, network);
                                  } catch (e) {
                                    Loggers.ui.e("$deviceId $e");
                                  } finally {
                                    overlay.hide();
                                  }
                                },
                                child: Text(
                                    AppLocalizations.of(context)!.confirmYes))
                          ],
                        );
                      });
                }))
            .toList() ??
        List.empty();

    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: ListView(
          children: WH.divideWith(() => const Divider(), [
        ...networks,
        addNetworkOption(context),
        ConfigureAutomaticUploadListItem(station: station),
      ])),
    );
  }
}

class ConfigureAutomaticUploadPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const ConfigureAutomaticUploadPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final StationConfiguration configuration =
        context.watch<AppState>().configuration;

    Loggers.ui.i("station $station $config");

    final enabled = station.ephemeral?.transmission?.enabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: WH.padPage(Column(children: [
        if (!enabled)
          WH.align(WH.vertical(ElevatedButton(
              onPressed: () async {
                Loggers.ui.i("wifi-upload:enable");
                await configuration.enableWifiUploading(station.deviceId);
              },
              child: const Text("Enable")))),
        if (enabled)
          WH.align(WH.vertical(ElevatedButton(
              onPressed: () async {
                Loggers.ui.i("wifi-upload:disable");
                await configuration.disableWifiUploading(station.deviceId);
              },
              child: const Text("Disable"))))
      ])),
    );
  }
}

class WifiNetworkListItem extends StatelessWidget {
  final NetworkConfig network;
  final VoidCallback onRemove;

  const WifiNetworkListItem({
    super.key,
    required this.network,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(network.ssid),
      onTap: () async {
        onRemove();
      },
    );
  }
}

class ConfigureAutomaticUploadListItem extends StatelessWidget {
  final StationModel station;

  const ConfigureAutomaticUploadListItem({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.settingsAutomaticUpload),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfigureAutomaticUploadPage(
              station: station,
            ),
          ),
        );
      },
    );
  }
}

class WifiNetwork {
  String? ssid;
  String? password;
  bool preferred;

  WifiNetwork(
      {required this.ssid, required this.password, required this.preferred});
}

class WifiNetworkForm extends StatefulWidget {
  final void Function(WifiNetwork) onSave;
  final WifiNetwork original;

  const WifiNetworkForm(
      {super.key, required this.onSave, required this.original});

  @override
  State<WifiNetworkForm> createState() => _WifiNetworkFormState();
}

class _WifiNetworkFormState extends State<WifiNetworkForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.networkEditTitle),
      ),
      body: FormBuilder(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FormBuilderTextField(
              name: 'ssid',
              initialValue: widget.original.ssid,
              decoration: InputDecoration(labelText: localizations.wifiSsid),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            FormBuilderTextField(
              name: 'password',
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: localizations.wifiPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_passwordVisible,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.saveAndValidate()) {
                  final ssid = _formKey.currentState!.value['ssid'];
                  final password = _formKey.currentState!.value['password'];
                  widget.onSave(WifiNetwork(
                      ssid: ssid, password: password, preferred: false));
                  /*
                  final overlay = context.loaderOverlay;
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final email = _formKey.currentState!.value['email'];
                  final password = _formKey.currentState!.value['password'];
                  overlay.show();
                  try {
                    final saved = await accounts.addOrUpdate(email, password);
                    if (saved != null) {
                      navigator.pop();
                    } else {
                      messenger.showSnackBar(SnackBar(
                        content: Text(localizations.accountFormFail),
                      ));
                    }
                  } catch (error) {
                    Loggers.portal.e("$error");
                  } finally {
                    overlay.hide();
                  }
                  */
                }
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(AppColors.primaryColor),
                padding: MaterialStateProperty.all<EdgeInsets>(
                    const EdgeInsets.symmetric(
                        vertical: 24.0, horizontal: 32.0)),
              ),
              child: Text(
                localizations.networkSaveButton,
                style: WH.buttonStyle(18),
              ),
            ),
          ]
              .map((child) =>
                  Padding(padding: const EdgeInsets.all(8), child: child))
              .toList(),
        ),
      ),
    );
  }
}
