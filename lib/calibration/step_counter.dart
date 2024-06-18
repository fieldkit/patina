import 'package:flutter/foundation.dart';

class StepCounter with ChangeNotifier {
  int _steps = 1;

  int get steps => _steps;

  void increment() {
    _steps++;
    notifyListeners();
  }
}
