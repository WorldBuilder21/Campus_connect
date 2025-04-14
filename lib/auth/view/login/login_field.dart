import 'package:campus_conn/auth/api/auth_repository.dart';
import 'package:campus_conn/auth/providers/account_provider.dart';
import 'package:campus_conn/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginField extends ConsumerStatefulWidget {
  const LoginField({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginFieldState();
}

class _LoginFieldState extends ConsumerState<LoginField> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    // TODO: implement dispose
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await authRepo.signInWithPassword(email: email, password: password);

      final account = await authRepo.getAccount(authRepo.userId);
      if (!mounted) return;

      ref.read(currentAccount.notifier).state == account;

      // verify email

      // move to the home screen
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (context) => false);
    } catch (error) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
