import 'package:campus_conn/auth/widget/password_strength_checker.dart';
import 'package:campus_conn/core/widget/reusable_text_form_field.dart';
import 'package:flutter/material.dart';

class PasswordScreen extends StatefulWidget {
  final TextEditingController password;
  final TextEditingController confirmpassword;
  final Key formkey;
  const PasswordScreen({
    super.key,
    required this.password,
    required this.confirmpassword,
    required this.formkey,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _isStrong = false;
  bool _obscureText = true;
  bool _confirmObscureText = true;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: FractionallySizedBox(
          widthFactor: 0.9,
          child: Form(
            key: widget.formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create your account password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                        child: Text(
                            'Your password must be at least 8 characters long, and contain at least one letter, one digit and one special character.'),
                      ),
                    )
                  ],
                ),
                ReusableTextFormField(
                  maxLines: 1,
                  focusNode: _passwordFocusNode,
                  hintText: 'Password',
                  obscureText: _obscureText,
                  controller: widget.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                  functionValidate: (String? value) {
                    RegExp regExp = RegExp(
                        r"^(?=.*[A-Z])(?=.*[!@#\$%^&*(),.?:{}|<>])(?=.*\d).{8,}$");
                    if (value!.isEmpty) {
                      return "This field cannot be empty";
                    } else if (!regExp.hasMatch(value)) {
                      return "Invalid password";
                    }
                  },
                ),
                const SizedBox(height: 15),
                ReusableTextFormField(
                  maxLines: 1,
                  focusNode: _confirmFocusNode,
                  controller: widget.confirmpassword,
                  obscureText: _confirmObscureText,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmObscureText
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmObscureText = !_confirmObscureText;
                        print(_confirmObscureText);
                      });
                    },
                  ),
                  onSubmitField: (term) {
                    _confirmFocusNode.unfocus();
                  },
                  onChangedFunc: (String value) {
                    setState(() {
                      widget.confirmpassword.text = value;
                    });
                  },
                  functionValidate: (String? value) {
                    if (value!.isEmpty) {
                      return "This field cannot be empty";
                    } else if (widget.password.text != value) {
                      return "Passwords do not match";
                    }
                  },
                  hintText: 'Confirm password',
                ),
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: widget.password,
                      builder: (context, child) {
                        final password = widget.password.text;

                        return PasswordStrengthChecker(
                          onStrengthChanged: (bool value) {
                            setState(() {
                              _isStrong = value;
                            });
                          },
                          password: password,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
