import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fk/common_widgets.dart';

import '../app_state.dart';

class AccountsList extends StatelessWidget {
  final PortalAccounts accounts;
  final void Function(PortalAccount) onActivate;
  final void Function(PortalAccount) onDelete;
  final void Function(PortalAccount) onLogin;

  const AccountsList(
      {super.key,
      required this.accounts,
      required this.onActivate,
      required this.onDelete,
      required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final items = accounts.accounts
        .map(
          (account) => AccountItem(
              account: account,
              onActivate: () => onActivate(account),
              onLogin: () => onLogin(account),
              onDelete: () => onDelete(account)),
        )
        .toList();
    return Column(children: items);
  }
}

class AccountStatus extends StatelessWidget {
  final Validity validity;
  final bool active;

  const AccountStatus(
      {super.key, required this.validity, required this.active});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    text(value) => Container(
        width: double.infinity, margin: WH.pagePadding, child: Text(value));

    switch (validity) {
      case Validity.connectivity:
        return ColoredBox(
            color: const Color.fromRGBO(250, 197, 89, 1),
            child: text(localizations.accountConnectivity));
      case Validity.unknown:
        return ColoredBox(
            color: const Color.fromRGBO(250, 197, 89, 1),
            child: text(localizations.accountUnknown));
      case Validity.invalid:
        return ColoredBox(
            color: const Color.fromRGBO(240, 144, 141, 1),
            child: text(localizations.accountInvalid));
      case Validity.valid:
        if (active) {
          return text(localizations.accountDefault);
        } else {
          return const SizedBox.shrink();
        }
    }
  }
}

class AccountItem extends StatelessWidget {
  final PortalAccount account;
  final VoidCallback onActivate;
  final VoidCallback onDelete;
  final VoidCallback onLogin;

  const AccountItem(
      {super.key,
      required this.account,
      required this.onActivate,
      required this.onDelete,
      required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BorderedListItem(
        header:
            GenericListItemHeader(title: account.email, subtitle: account.name),
        children: [
          WH.align(AccountStatus(
              validity: account.validity, active: account.active)),
          WH.align(WH.padChildrenPage([
            Row(
              children: WH.padButtonsRow([
                ElevatedTextButton(
                    onPressed: onDelete,
                    text: localizations.accountDeleteButton),
                if (account.validity != Validity.valid)
                  ElevatedTextButton(
                      onPressed: onLogin,
                      text: localizations.accountRepairButton),
              ]),
            )
          ]))
        ]);
  }
}
