import 'package:flutter/material.dart';

const Color logoBlue = Color.fromRGBO(27, 128, 201, 1);

class FullScreenLogo extends StatelessWidget {
  const FullScreenLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
          Image.asset("resources/images/logo_fk_blue.png"),
          const Padding(padding: EdgeInsets.only(top: 50), child: SizedBox(width: 100, height: 100, child: CircularProgressIndicator()))
        ]));
  }
}
