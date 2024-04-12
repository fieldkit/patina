import 'package:fk/common_widgets.dart';
import 'package:fk/reader/screens.dart';
import 'package:flows/flows.dart' as flows;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onDone;

  const WelcomeScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return PopScope(
        onPopInvoked: (bool didPop) async {
          if (didPop) {
            onDone();
          }
        },
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('resources/images/logo_fk_blue.png'),
                  Image.asset('resources/images/art/welcome.jpg'),
                  Text(
                    AppLocalizations.of(context)!.welcomeTitle,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    AppLocalizations.of(context)!.welcomeMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Divider(
                    color: Colors.grey[300],
                    thickness: 1.0,
                    indent: 50,
                    endIndent: 50,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                    child: ElevatedTextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProvideContentFlowsWidget(
                                    child: QuickFlow(
                                        start: flows.StartFlow(
                                            prefix: "onboarding"))),
                          ),
                        );
                      },
                      text: AppLocalizations.of(context)!.welcomeButton,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onDone(); // Call the onDone callback when the skip button is pressed
                    },
                    child: Text(
                      AppLocalizations.of(context)!.skipInstructions,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
