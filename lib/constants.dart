// constants.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFFCE596B);
  static const Color logoBlue = Color.fromRGBO(27, 128, 201, 1);
  static const Color text = Color(0xFF2C3E50);
}

class AppIcons {
  static const String stationConnected =
      "resources/images/icon_station_connected.png";
  static const String stationNotConnected =
      "resources/images/icon_station_not_connected.png";
}

class AppStyles {
  static const TextStyle title = TextStyle(
    fontFamily: "Avenir-Medium",
    color: Color.fromARGB(255, 0, 44, 44),
    fontWeight: FontWeight.w500,
    fontSize: 17,
  );
}
