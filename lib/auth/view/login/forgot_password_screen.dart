import 'package:campus_conn/auth/api/auth_repository.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/core/widget/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  static const routeName = '/forgot-password';
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  String? _emailError;
  bool _isLoading = false;
  bool _emailSent = false;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    // Start the animations
    _animationController.forward();

    // Add listener to focus node
    _emailFocusNode.addListener(_handleEmailFocusChange);
  }

  void _handleEmailFocusChange() {
    if (_emailFocusNode.hasFocus) {
      setState(() {
        _emailError = null;
      });
    } else {
      _validateEmail();
    }
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
        _emailError = 'Please enter a valid email';
      } else {
        _emailError = null;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Validate email
    _validateEmail();
    if (_emailError != null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPassword(email: _emailController.text.trim());

      if (mounted) {
        // Show success even if the email doesn't actually exist
        // This is for security reasons - we don't want to reveal which emails exist
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });

        // Wait for success animation to show
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
            context.showAlert(
              'If an account with this email exists, you\'ll receive password reset instructions.',
              AppTheme.successColor,
            );
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);

        // Don't show specific errors for privacy/security reasons
        context.showAlert(
          'There was a problem sending the reset email. Please try again later.',
          AppTheme.errorColor,
        );

        // Log the actual error for debugging
        debugPrint('Reset password error: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimaryColor,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              height: size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Success animation or icon
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _emailSent
                            ? _buildSuccessAnimation()
                            : _buildResetIcon(),
                      ),

                      const SizedBox(height: 30),

                      // Title with animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _emailSent
                            ? const Text(
                                'Email Sent!',
                                key: ValueKey('success-title'),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : const Text(
                                'Forgot Your Password?',
                                key: ValueKey('reset-title'),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Description with animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _emailSent
                            ? Text(
                                "We've sent the password reset instructions to your email.",
                                key: const ValueKey('success-desc'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              )
                            : Text(
                                "No worries! Enter your email and we'll send you reset instructions.",
                                key: const ValueKey('reset-desc'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                      ),

                      const SizedBox(height: 40),

                      // Form with animation
                      AnimatedOpacity(
                        opacity: _emailSent ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: FractionallySizedBox(
                          widthFactor: isMobile ? 1.0 : 0.5,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email field
                                TextFormField(
                                  enabled: !_emailSent,
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  cursorColor: AppTheme.primaryColor,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'Enter your email address',
                                    errorText: _emailError,
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: _emailFocusNode.hasFocus
                                          ? AppTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.auto,
                                  ),
                                  onFieldSubmitted: (_) => _resetPassword(),
                                ),

                                const SizedBox(height: 30),

                                // Reset button with gradient
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: AppTheme.primaryGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor:
                                          Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed:
                                        _isLoading ? null : _resetPassword,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Reset Password',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Back to login button
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          size: 16,
                        ),
                        label: const Text(
                          'Back to Login',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.subtleGrey,
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Icon(
        Icons.lock_reset_rounded,
        size: 50,
        color: AppTheme.primaryColor,
        key: ValueKey('reset-icon'),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Icon(
        Icons.check_circle,
        size: 60,
        color: AppTheme.successColor,
        key: ValueKey('success-icon'),
      ),
    );
  }
}
