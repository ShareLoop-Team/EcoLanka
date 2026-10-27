// AuthController — OTP sign-in flow (MVC controller).
// Depends on the AuthRepository abstraction, not on the HTTP API (DIP).

import '../repositories/repositories.dart';

class AuthController {
  AuthController(this._auth);

  final AuthRepository _auth;

  static final RegExp _sixDigits = RegExp(r'^\d{6}$');

  String? get currentUid => _auth.currentUid;
  String? get currentPhone => _auth.currentPhone;
  bool get isSignedIn => _auth.currentUid != null;

  /// Sends an OTP to a +94 number. Returns true if Android verified instantly.
  Future<bool> sendCode(String phoneE164) {
    if (!phoneE164.startsWith('+94') || phoneE164.length != 12) {
      throw StateError('Enter a valid Sri Lankan mobile number.');
    }
    return _auth.sendCode(phoneE164);
  }

  Future<void> verifyCode(String code) {
    if (!_sixDigits.hasMatch(code)) {
      throw StateError('Enter the 6-digit code from the SMS.');
    }
    return _auth.verifyCode(code);
  }

  Future<void> signOut() => _auth.signOut();

  String messageFor(Object error) => _auth.messageFor(error);
  bool isInvalidCode(Object error) => _auth.isInvalidCode(error);
}
