// AuthRepository using the API's own SMS codes (default) — phone (OTP) sign-in against the
// Laravel backend (POST /auth/send-code, POST /auth/verify).
//
// The SMS is sent by the backend's SMS_DRIVER (httpsms = your Android phone,
// notifylk, or log for development).
//
// Test numbers (no SMS sent — see backend/.env OTP_TEST_NUMBERS):
//   +94 77 000 0001 / 123456
//   +94 77 000 0002 / 123456

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../repositories/repositories.dart';
import 'api_client.dart';

class ApiAuthService implements AuthRepository {
  ApiAuthService(this._api);

  final ApiClient _api;
  String? _pendingPhone;

  @override
  String? get currentUid => _api.hasSession ? _api.uid : null;

  @override
  String? get currentPhone => _api.hasSession ? _api.phone : null;

  @override
  Future<bool> sendCode(String phoneE164) async {
    final res = await _api.post('/auth/send-code', {'phone': phoneE164}) as Map<String, dynamic>;
    _pendingPhone = phoneE164;
    final debugCode = res['debugCode'];
    if (debugCode != null) {
      // Only returned when the server runs with OTP_EXPOSE_CODE=true (local dev).
      debugPrint('Shareloop OTP for $phoneE164: $debugCode');
    }
    return false; // the user always types the code
  }

  @override
  Future<void> verifyCode(String smsCode) async {
    final phone = _pendingPhone;
    if (phone == null) throw StateError('Request a verification code first.');
    final res = await _api.post('/auth/verify', {'phone': phone, 'code': smsCode})
        as Map<String, dynamic>;
    await _api.saveSession(
      token: res['token'] as String,
      uid: res['uid'] as String,
      phone: res['phone'] as String?,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      if (_api.hasSession) await _api.post('/auth/logout');
    } catch (_) {
      // Offline — forget the token locally anyway.
    }
    await _api.clearSession();
  }

  @override
  bool isInvalidCode(Object error) =>
      error is ApiException && error.code == 'invalid-verification-code';

  @override
  String messageFor(Object error) {
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
