import 'package:caldor/calibration.dart';
import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fk/diagnostics.dart';
import 'package:fk/gen/api.dart';
import 'package:fk/meta.dart';
import 'package:flows/flows.dart';
import 'package:flutter/foundation.dart';

import '../app_state.dart';

class ActiveCalibration extends ChangeNotifier {
  double? _standard;

  double? get standard => _standard;

  bool get invalid => _standard == null;

  void haveStandard(double? standard) {
    _standard = standard;
    notifyListeners();
  }

  @override
  String toString() => "Active(standard = $_standard)";

  UserStandard userStandard() {
    return UserStandard(_standard!);
  }
}

class CalibrationConfig {
  final ModuleIdentity moduleIdentity;
  final CurveType curveType;
  final List<Standard> standards;
  final List<Step> steps;

  Standard get standard => standards.first;

  bool get done => standards.isEmpty;

  Step? get step => steps.firstOrNull;

  CalibrationConfig._internal({
    required this.moduleIdentity,
    required this.curveType,
    required this.standards,
    required this.steps,
  });

  static List<Step> getSteps(ModuleConfig module,
      AppLocalizations localizations, ContentFlows content) {
    final localized = LocalizedModule.get(module, localizations);
    final template = localized.calibrationTemplate!;
    final help = CalibrationHelp.fromModule(module, content);
    final standardSteps =
        template.standards.map((e) => StandardStep(standard: e));

    if (help.standards.length != template.standards.length) {
      Loggers.cal.i("mismatched standard steps, no help");
      return standardSteps.toList();
    }

    // Tried to use IterableZip here and it was messy.
    final List<Step> steps = List.empty(growable: true);
    for (var i = 0; i < template.standards.length; ++i) {
      for (final screen in help.standards[i]) {
        steps.add(HelpStep(screen: screen));
      }
      steps.add(StandardStep(standard: template.standards[i]));
    }

    return steps;
  }

  static CalibrationConfig fromModule(ModuleConfig module,
      AppLocalizations localizations, ContentFlows content) {
    final localized = LocalizedModule.get(module, localizations);
    final template = localized.calibrationTemplate!;
    final steps = getSteps(module, localizations, content);
    return CalibrationConfig._internal(
        moduleIdentity: module.identity,
        curveType: template.curveType,
        steps: steps,
        standards: List.from(template.standards));
  }

  CalibrationConfig popStandard() {
    standards.removeAt(0);
    return this;
  }
}

class CalibrationHelp {
  final List<List<String>> standards;

  CalibrationHelp({required this.standards});

  static CalibrationHelp fromModule(ModuleConfig module, ContentFlows content) {
    switch (module.key) {
      case "modules.water.temp":
        final List<String> standard =
            content.getScreenNamesWithPrefix("calibration.water.temp.");
        return CalibrationHelp(standards: [standard, standard, standard]);
      case "modules.water.ph":
        final List<String> standard =
            content.getScreenNamesWithPrefix("calibration.water.ph.");
        return CalibrationHelp(standards: [standard, standard, standard]);
      case "modules.water.orp":
        final List<String> standard =
            content.getScreenNamesWithPrefix("calibration.water.orp.");
        return CalibrationHelp(standards: [standard, standard, standard]);
      case "modules.water.do":
        final List<String> standard =
            content.getScreenNamesWithPrefix("calibration.water.dox.");
        return CalibrationHelp(standards: [standard, standard, standard]);
      case "modules.water.ec":
        final List<String> standard =
            content.getScreenNamesWithPrefix("calibration.water.ec.");
        return CalibrationHelp(standards: [standard, standard, standard]);
    }
    return CalibrationHelp(standards: List.empty());
  }
}

class Step {}

class HelpStep extends Step {
  final String screen;

  HelpStep({required this.screen});
}

class StandardStep extends Step {
  final Standard standard;

  StandardStep({required this.standard});
}
