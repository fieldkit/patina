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
                  Image.asset('resources/images/logo_fk_blue.png', height: 50),
                  const SizedBox(height: 20),
                  Image.asset('resources/images/art/welcome.jpg', height: 380),
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
                  const SizedBox(height: 30),
                  Divider(
                    color: Colors.grey[300],
                    thickness: 1.0,
                    indent: 50,
                    endIndent: 50,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(50, 10, 50, 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProvideContentFlowsWidget(
                                    child: QuickFlow(
                                        start: StartFlow(name: "onboarding"))),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCE596B),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 100.0, vertical: 14.0),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.welcomeButton,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onDone(); // Call the onDone callback when the skip button is pressed
                    },
                    child: Text(
                      AppLocalizations.of(context)!
                          .skipInstructions, // Assuming you have the localization set up for 'skipInstructions'
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
