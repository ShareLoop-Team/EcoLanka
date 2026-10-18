import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isInputValid = false;
  bool _isLoading = false;

  // Rate Limiting Security Controls
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  // Strict Regex for Sri Lankan Mobile Prefixes
  // 70, 71, 72, 74, 75, 76, 77, 78
  static final RegExp _slMobileRegex =
      RegExp(r'^7[01245678]\d{7}$');

  @override
  void initState() {
    super.initState();

    _phoneController.addListener(_validatePhoneNumber);
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Sanitizes input and validates Sri Lankan mobile numbers.
  void _validatePhoneNumber() {
    final cleanInput =
        _phoneController.text.replaceAll(RegExp(r'\D'), '');

    final isValid = _slMobileRegex.hasMatch(cleanInput);

    if (_isInputValid != isValid && mounted) {
      setState(() {
        _isInputValid = isValid;
      });
    }
  }

  /// Handles secure OTP request with anti-spam rate limiting.
  Future<void> _handleSendVerificationCode() async {
    if (!_isInputValid ||
        _cooldownSeconds > 0 ||
        _isLoading) {
      return;
    }

    // Unfocus keyboard.
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final sanitizedNumber =
          _phoneController.text.replaceAll(RegExp(r'\D'), '');

      final fullE164PhoneNumber = '+94$sanitizedNumber';

      // Ask Firebase to send the SMS code.
      final signedInInstantly =
          await AuthService.sendCode(fullE164PhoneNumber);

      if (!mounted) return;

      // Android can verify the number without a code.
      if (signedInInstantly) {
        final profile = await DatabaseService.getCurrentUserProfile();
        if (!mounted) return;
        context.go(profile == null ? '/profile-setup' : '/home');
        return;
      }

      // Start anti-abuse rate limit cooldown.
      _startRateLimitCooldown(30);

      // Navigate to OTP verification screen.
      // push (not go) so the back button returns here.
      context.push(
        '/otp-verification',
        extra: fullE164PhoneNumber,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.messageFor(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startRateLimitCooldown(int seconds) {
    setState(() {
      _cooldownSeconds = seconds;
    });

    _cooldownTimer?.cancel();

    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_cooldownSeconds <= 1) {
          timer.cancel();

          if (mounted) {
            setState(() {
              _cooldownSeconds = 0;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _cooldownSeconds--;
            });
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.black87,
          ),
          // Use GoRouter navigation.
          onPressed: () => context.pop(),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              const Text(
                'Enter Mobile Number',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'We will send an SMS verification code',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? AppColors.brandPrimary
                        : Colors.grey.shade300,
                    width: _focusNode.hasFocus ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'LK +94',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),

                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [
                          AutofillHints.telephoneNumberNational,
                        ],

                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],

                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: Colors.black87,
                        ),

                        decoration: InputDecoration(
                          hintText: '77 123 4567',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),

                        onSubmitted: (_) =>
                            _handleSendVerificationCode(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'By entering your number you agree to receive a '
                'one-time verification SMS. Standard SMS rates may apply.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.grey.shade500,
                ),
              ),

              const Spacer(),

              PrimaryButton(
                text: _cooldownSeconds > 0
                    ? 'Resend in ${_cooldownSeconds}s'
                    : (_isLoading
                        ? 'Sending...'
                        : 'Send Verification Code'),

                onPressed:
                    (_isInputValid &&
                            _cooldownSeconds == 0 &&
                            !_isLoading)
                        ? _handleSendVerificationCode
                        : null,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}