// Anti-resell policy guardrail (SRP): one place for the declaration text and
// the "is this a sale?" check. The same check is enforced in
// the API (backend/app/Support/Api.php → looksLikeSale).

class AntiResellPolicy {
  AntiResellPolicy._();

  /// Binding declaration from the Shareloop proposal.
  static const String declaration =
      'I confirm that I will not resell this donated item.';

  static const String blockedMessage =
      'Shareloop is for free giving — no prices or sales';

  static final RegExp _salePattern = RegExp(
    r'(\brs\.?\s*\d|\blkr\b|\bprice\b|for sale|\bselling\b|\bsell\b|\bcash\b|රු|ரூ)',
    caseSensitive: false,
  );

  /// True when [text] looks like a sale offer (price, "for sale", Rs. 500…).
  static bool looksLikeSale(String text) => _salePattern.hasMatch(text);
}
