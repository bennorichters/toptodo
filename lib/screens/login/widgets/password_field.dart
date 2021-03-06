import 'package:flutter/material.dart';

import 'package:toptodo/constants/keys.dart' as ttd_keys;

class PasswordField extends StatefulWidget {
  const PasswordField(this._controller);
  final TextEditingController _controller;

  @override
  State<StatefulWidget> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: const Key(ttd_keys.passwordFieldTextFormField),
            autocorrect: false,
            controller: widget._controller,
            obscureText: _obscured,
            decoration: const InputDecoration(
              labelText: 'application password',
              hintText: 'press the help (?) button for info',
            ),
            validator: (String value) =>
                value.isEmpty ? 'fill in your application password' : null,
          ),
        ),
        IconButton(
          key: const Key(ttd_keys.passwordFieldVisibleButton),
          icon: _obscured
              ? const Icon(Icons.visibility)
              : const Icon(Icons.visibility_off),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ],
    );
  }
}
