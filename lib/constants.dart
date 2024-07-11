// constants.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFFCE596B);
  static const Color logoBlue = Color.fromRGBO(27, 128, 201, 1);
  static const Color text = Color(0xFF2C3E50);
  static const LinearGradient blueGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: <Color>[
        Color.fromARGB(255, 0x23, 0x86, 0xcd),
        Color.fromARGB(255, 0x53, 0xb2, 0xe0)
      ]);
}

class AppIcons {
  static const String stationConnected =
      "resources/images/icon_station_connected.png";
  static const String stationNotConnected =
      "resources/images/icon_station_disconnected.svg";
}

class AppStyles {
  static const TextStyle title = TextStyle(
    fontFamily: "Avenir",
    color: Color.fromARGB(255, 0, 44, 44),
    fontWeight: FontWeight.w700,
    fontSize: 17,
  );
}
