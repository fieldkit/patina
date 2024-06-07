import 'package:flutter/material.dart';
import 'package:fk/loading_widget.dart';
import 'package:flutter/services.dart';

import 'gen/frb_generated.dart';

void main() async {
  await RustLib.init();

  // Necessary so we can call path_provider from startup, otherwise this is done
  // inside runApp. 'The "instance" getter on the ServicesBinding binding mixin
  // is only available once that binding has been initialized.'
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations to portraitUp and portraitDown
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const LoadingWidget());
  });
}
