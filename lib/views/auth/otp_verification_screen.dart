import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../config/constants.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPVerificationScreen> createState() =>
      _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();

  static const int _otpLength = 6; // Firebase SMS codes are 6 digits
  static const int _maxFailedAttempts = 3;

  int _resendCooldown = 30;
  Timer? _cooldownTimer;

  bool _isLoading = false;
  bool _isLockedOut = false;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    setState(() => _resendCooldown = 30);

    _cooldownTimer?.cancel();

    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_resendCooldown <= 1) {
          timer.cancel();

          if (mounted) {
            setState(() => _resendCooldown = 0);
          }
        } else {
          if (mounted) {
            setState(() => _resendCooldown--);
          }
        }
      },
    );
  }

  bool get _isOtpComplete =>
      _pinController.text.length == _otpLength;

  Future<void> _handleVerifyOTP() async {
    if (_isLockedOut || !_isOtpComplete || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      // Verify the code with Firebase and sign in.
      await AuthService.verifyCode(_pinController.text);
      _failedAttempts = 0;

      // Existing users go home; new users complete their profile.
      final profile = await DatabaseService.getCurrentUserProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP Verified Successfully!'),
          backgroundColor: AppColors.brandPrimary,
        ),
      );

      if (profile != null) {
        Provider.of<UserProvider>(context, listen: false)
            .updateDistrict(profile.district);
        context.go('/home');
      } else {
        context.go('/profile-setup');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'invalid-verification-code') {
        _handleFailedAttempt();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.messageFor(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResend() async {
    _startCooldownTimer();
    try {
      await AuthService.sendCode(widget.phoneNumber);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code has been sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.messageFor(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleFailedAttempt() {
    _failedAttempts++;
    _pinController.clear();

    if (_failedAttempts >= _maxFailedAttempts) {
      setState(() => _isLockedOut = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Too many failed attempts. Try again in 5 minutes.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      final int remaining =
          _maxFailedAttempts - _failedAttempts;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid OTP. $remaining attempt(s) remaining.',
          ),
          backgroundColor: Colors.deepOrange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
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
                'Verify Phone Number',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              RichText(
                text: TextSpan(
                  text: 'Enter the 6-digit code sent to ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  children: [
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              Center(
                child: Pinput(
                  controller: _pinController,
                  length: _otpLength,

                  enabled: !_isLockedOut && !_isLoading,

                  autofocus: true,
                  keyboardType: TextInputType.number,

                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],

                  defaultPinTheme: PinTheme(
                    width: 56,
                    height: 60,

                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),

                    decoration: BoxDecoration(
                      color: _isLockedOut
                          ? Colors.grey.shade200
                          : const Color(0xFFF6F8F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),

                  focusedPinTheme: PinTheme(
                    width: 56,
                    height: 60,

                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.brandPrimary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  onChanged: (value) {
                    setState(() {});
                  },

                  onCompleted: (pin) {
                    _handleVerifyOTP();
                  },
                ),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  TextButton(
                    onPressed:
                        (_resendCooldown == 0 && !_isLockedOut)
                            ? _handleResend
                            : null,

                    child: Text(
                      _resendCooldown > 0
                          ? 'Resend in ${_resendCooldown}s'
                          : 'Resend Code',

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            (_resendCooldown == 0 &&
                                    !_isLockedOut)
                                ? AppColors.brandPrimary
                                : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              PrimaryButton(
                text: _isLockedOut
                    ? 'Account Blocked'
                    : (_isLoading
                        ? 'Verifying...'
                        : 'Verify Code'),

                onPressed:
                    (_isOtpComplete &&
                            !_isLoading &&
                            !_isLockedOut)
                        ? _handleVerifyOTP
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