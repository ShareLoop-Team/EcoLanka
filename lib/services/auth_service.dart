// Phone (OTP) sign-in with Firebase Auth.
//
// Mobile (Android/iOS): verifyPhoneNumber → codeSent → signInWithCredential.
// Web: signInWithPhoneNumber shows an invisible reCAPTCHA, then confirm(code).
//
// Test numbers (no SMS sent, no quota used):
//   +94 77 000 0001 / 123456
//   +94 77 000 0002 / 123456

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _verificationId;
  static int? _resendToken;
  static ConfirmationResult? _webConfirmation;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Requests an SMS code for [phoneE164] (e.g. +94771234567).
  ///
  /// Returns `true` if Android verified the number instantly and the user is
  /// already signed in (no code needed), otherwise `false` once the SMS is sent.
  static Future<bool> sendCode(String phoneE164) async {
    if (kIsWeb) {
      _webConfirmation = await _auth.signInWithPhoneNumber(phoneE164);
      return false;
    }

    final completer = Completer<bool>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) completer.complete(true);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete(false);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
    return completer.future;
  }

  /// Checks the 6-digit [smsCode] and signs the user in.
  static Future<User> verifyCode(String smsCode) async {
    final UserCredential result;
    if (kIsWeb) {
      final confirmation = _webConfirmation;
      if (confirmation == null) {
        throw StateError('Request a verification code first.');
      }
      result = await confirmation.confirm(smsCode);
    } else {
      final id = _verificationId;
      if (id == null) {
        throw StateError('Request a verification code first.');
      }
      result = await _auth.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: id, smsCode: smsCode),
      );
    }
    return result.user!;
  }

  static Future<void> signOut() => _auth.signOut();

  /// User-friendly message for an auth error.
  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      debugPrint('FirebaseAuthException: ${error.code} | ${error.message}');
      switch (error.code) {
        case 'invalid-phone-number':
          return 'That phone number is not valid.';
        case 'invalid-verification-code':
          return 'Incorrect code. Please check and try again.';
        case 'session-expired':
        case 'code-expired':
          return 'The code expired. Please request a new one.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a while and try again.';
        case 'quota-exceeded':
          return 'Daily SMS limit reached. Use a test number or try tomorrow.';
        case 'network-request-failed':
          return 'No internet connection.';
      }
      return 'Sign-in failed (${error.code}).';
    }
    debugPrint('Auth error: $error');
    if (error is StateError) return error.message;
    return 'Something went wrong. Please try again.';
  }
}
