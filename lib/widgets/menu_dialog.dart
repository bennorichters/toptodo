import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:toptodo_data/toptodo_data.dart';

import 'package:toptodo/constants/keys.dart' as ttd_keys;
import 'package:toptodo/screens/login/login_screen.dart';
import 'package:toptodo/widgets/dialog_header.dart';
import 'package:toptodo/widgets/td_model_avatar.dart';

class MenuDialog extends StatelessWidget {
  const MenuDialog({
    @required this.currentOperator,
    @required this.showSettings,
  });

  final TdOperator currentOperator;
  final bool showSettings;

  static const _divider = Divider(
    thickness: 1,
    indent: 10,
    endIndent: 10,
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DialogHeader(),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TdModelAvatar(
                    currentOperator,
                    diameter: 35,
                  ),
                  const SizedBox(width: 20),
                  Text(currentOperator.name),
                ],
              ),
            ),
            _divider,
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSettings)
                    _MenuItem(
                      iconData: Icons.settings,
                      text: 'settings',
                      onTap: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                        Navigator.pushNamed(context, 'settings');
                      },
                    ),
                  if (showSettings) const SizedBox(height: 20),
                  _MenuItem(
                    iconData: Icons.power_settings_new,
                    text: 'log out',
                    onTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      Navigator.pushReplacementNamed(
                        context,
                        'login',
                        arguments: const LoginScreenArguments(logOut: true),
                      );
                    },
                  ),
                ],
              ),
            ),
            _divider,
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    key: const Key(ttd_keys.menuDialogRichText),
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'TOPtodo',
                          style: const TextStyle(color: Colors.blue),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              launch(
                                'https://bennorichters.github.io/TOPtodo/',
                              );
                            },
                        ),
                        const TextSpan(
                          text: ' is an open source project.',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    @required this.iconData,
    @required this.text,
    this.onTap,
    Key key,
  }) : super(key: key);
  final IconData iconData;
  final String text;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(iconData),
          ),
          Text(text),
        ],
      ),
    );
  }
}
