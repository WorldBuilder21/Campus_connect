import 'package:flutter/material.dart';

class PasswordStrengthChecker extends StatefulWidget {
  const PasswordStrengthChecker(
      {super.key, required this.password, required this.onStrengthChanged});

  /// Password value: obtained from a text field
  final String password;

  /// Callback that will be called when password strength changes
  final Function(bool isStrong) onStrengthChanged;

  @override
  State<PasswordStrengthChecker> createState() =>
      _PasswordStrengthCheckerState();
}

class _PasswordStrengthCheckerState extends State<PasswordStrengthChecker> {
  @override
  void didUpdateWidget(covariant PasswordStrengthChecker oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Check if the password value has changed
    if (widget.password != oldWidget.password) {
      /// If changed, re-validate the password strength
      final isStrong = _validators.entries.every(
        (entry) => entry.key.hasMatch(widget.password),
      );

      /// Call callback with new value to notify parent widget
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onStrengthChanged(isStrong),
      );
    }
  }

  final Map<RegExp, String> _validators = {
    RegExp(r'[A-Z]'): 'Has at least one uppercase letter?',
    RegExp(r'[!@#\$%^&*(),.?":{}|<>]'): 'Has at least One special character?',
    RegExp(r'\d'): 'Has at least one digit?',
    RegExp(r'^.{8,}$'): 'Has at least 8 characters?',
  };

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.password.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _validators.entries.map(
        (entry) {
          final hasMatch = entry.key.hasMatch(widget.password);

          final color =
              hasValue ? (hasMatch ? Colors.green : Colors.red) : Colors.red;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                hasValue
                    ? (hasMatch
                        ? const Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : const Icon(
                            Icons.close,
                            color: Colors.red,
                          ))
                    : const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                const SizedBox(
                  width: 5.0,
                ),
                Text(
                  entry.value,
                  style: TextStyle(color: color),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }
}
