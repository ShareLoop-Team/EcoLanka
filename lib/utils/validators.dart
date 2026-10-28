// Form validation (DRY): one set of validators shared by every form.
// Anti-resell wording checks live in AntiResellPolicy (SRP).

import 'anti_resell_policy.dart';

class Validators {
  Validators._();

  static final RegExp _slMobile = RegExp(r'^7[01245678]\d{7}$');

  /// True when [text] looks like a sale offer (price, "for sale", Rs. 500…).
  static bool looksLikeSale(String text) => AntiResellPolicy.looksLikeSale(text);

  /// 9-digit Sri Lankan mobile number without the leading 0 / +94.
  static bool isSriLankanMobile(String digits) => _slMobile.hasMatch(digits);

  static String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return 'Please enter your name';
    if (v.length > 50) return 'Name is too long';
    return null;
  }

  static String? itemTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 3) return 'Title must be at least 3 characters';
    if (v.length > 80) return 'Title must be 80 characters or less';
    if (looksLikeSale(v)) return AntiResellPolicy.blockedMessage;
    return null;
  }

  static String? itemDescription(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please describe the item';
    if (v.length > 1000) return 'Description must be 1000 characters or less';
    if (looksLikeSale(v)) return AntiResellPolicy.blockedMessage;
    return null;
  }

  /// Mandatory "reason" when requesting an item or posting a need.
  static String? requestMessage(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 5) return 'Tell the donor why you need it (min 5 characters)';
    if (v.length > 500) return 'Reason must be 500 characters or less';
    return null;
  }

  static String? needTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 3) return 'Say what you need (min 3 characters)';
    if (v.length > 80) return 'Must be 80 characters or less';
    return null;
  }

  static String? reviewComment(String? value) {
    final v = value?.trim() ?? '';
    if (v.length > 500) return 'Comment must be 500 characters or less';
    return null;
  }

  static String? reportDetails(String? value) {
    final v = value?.trim() ?? '';
    if (v.length > 500) return 'Details must be 500 characters or less';
    return null;
  }
}
