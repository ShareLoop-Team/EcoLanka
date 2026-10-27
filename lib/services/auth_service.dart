// Phone (OTP) sign-in with Firebase Authentication, then a session on the
// Shareloop Laravel API.
//
// 1. Firebase sends / checks the SMS code:
//      Mobile (Android/iOS): verifyPhoneNumber → codeSent → signInWithCredential.
//      Web: signInWithPhoneNumber (invisible reCAPTCHA) → confirm(code).
// 2. The Firebase ID token is exchanged at POST /api/auth/firebase for the
//    API's bearer token. Everything else (profiles, items, requests…) is the
//    Laravel API — Firebase is used for sign-in only.
//
// Test numbers (set in the Firebase console — no SMS sent, no quota used):
//   +94 77 000 0001 / 123456   (Nimal in the demo data)
//   +94 77 000 0002 / 123456   (Kavya in the demo data)

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../repositories/repositories.dart';
import 'api_client.dart';

class FirebaseAuthService implements AuthRepository {
  FirebaseAuthService(this._api, {FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final ApiClient _api;
  final FirebaseAuth _auth;

  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _webConfirmation;

  /// The API user id (what items, requests and profiles refer to).
  @override
  String? get currentUid => _api.hasSession ? _api.uid : null;

  @override
  String? get currentPhone =>
      _api.hasSession ? (_api.phone ?? _auth.currentUser?.phoneNumber) : null;

  @override
  Future<bool> sendCode(String phoneE164) async {
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
        // Android verified the number by itself (instant / auto-retrieval).
        try {
          await _auth.signInWithCredential(credential);
          await _startApiSession();
          if (!completer.isCompleted) completer.complete(true);
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
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

  @override
  Future<void> verifyCode(String smsCode) async {
    if (kIsWeb) {
      final confirmation = _webConfirmation;
      if (confirmation == null) {
        throw StateError('Request a verification code first.');
      }
      await confirmation.confirm(smsCode);
    } else {
      final id = _verificationId;
      if (id == null) {
        throw StateError('Request a verification code first.');
      }
      await _auth.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: id, smsCode: smsCode),
      );
    }
    await _startApiSession();
  }

  /// Firebase ID token → Shareloop API bearer token.
  Future<void> _startApiSession() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign-in did not complete. Please try again.');
    final idToken = await user.getIdToken(true);
    final res = await _api.post('/auth/firebase', {'idToken': idToken}) as Map<String, dynamic>;
    await _api.saveSession(
      token: res['token'] as String,
      uid: res['uid'] as String,
      phone: res['phone'] as String? ?? user.phoneNumber,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      if (_api.hasSession) await _api.post('/auth/logout');
    } catch (_) {
      // Offline — forget the API token locally anyway.
    }
    await _api.clearSession();
    await _auth.signOut();
  }

  @override
  bool isInvalidCode(Object error) =>
      error is FirebaseAuthException && error.code == 'invalid-verification-code';

  @override
  String messageFor(Object error) {
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
        case 'operation-not-allowed':
          return 'SMS to this region is not enabled yet (Firebase SMS region policy).';
        case 'app-not-authorized':
        case 'missing-client-identifier':
          return 'This app build is not registered in Firebase yet (add its SHA-1 fingerprint).';
      }
      return 'Sign-in failed (${error.code}).';
    }
    if (error is ApiException) {
      debugPrint('ApiException: ${error.statusCode} ${error.code} | ${error.message}');
      return error.message;
    }
    if (error is StateError) return error.message;
    if (error is TimeoutException || error is http.ClientException) {
      return 'Cannot reach the Shareloop server. Check your internet connection.';
    }
    debugPrint('Auth error: $error');
    return 'Something went wrong. Please try again.';
  }
}
