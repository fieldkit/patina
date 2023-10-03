import 'package:fk/reader/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onDone;

  const WelcomeScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          onDone();
          return true; // return true to allow the pop action
        },
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('resources/images/logo_fk_blue.png', height: 100),

                  const SizedBox(height: 20),

                  Image.asset('resources/images/art/welcome.jpg', height: 200),

                  const SizedBox(height: 20),

                  Text(
                    AppLocalizations.of(context)!.welcomeTitle,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    AppLocalizations.of(context)!.welcomeMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  // Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProvideContentFlowsWidget(
                              child: QuickFlow(
                                  start: StartFlow(name: "onboarding"))),
                        ),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.welcomeButton),
                  ),

                  const SizedBox(height: 10),

                  // TODO: Skip Button
                ],
              ),
            ),
          ),
        ));
  }
}
