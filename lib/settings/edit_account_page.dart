import 'package:flutter/material.dart';
import 'package:fk/settings/account_form_widget.dart';

import '../app_state.dart';

class EditAccountPage extends StatelessWidget {
  final PortalAccount original;

  const EditAccountPage({super.key, required this.original});

  @override
  Widget build(BuildContext context) {
    return AccountForm(original: original);
  }
}
