/// 논술 Credit in-app products (Owner-approved economics, 2026-10-09).
///
/// Credit is a **consumable** digital product (Apple Consumable IAP / Google
/// Play consumable one-time product), never a subscription. The approved KRW
/// price is a display fallback only — the store returns the authoritative,
/// localized price at runtime. The app never grants Credit: a purchase is
/// verified and posted to the canonical server ledger (provider `APPLE_IAP` /
/// `GOOGLE_PLAY`), and the balance is then re-read from `credit_summary`.
///
/// Product IDs are **proposed candidates** pending Store Console registration
/// (see the billing wiki). If the repo/wiki/console already holds approved IDs,
/// reuse those instead of creating duplicates.
class CreditProduct {
  const CreditProduct({
    required this.id,
    required this.credits,
    required this.approvedKrw,
  });

  /// Store product identifier (App Store Connect / Play Console).
  final String id;

  /// Credits granted on server-verified purchase.
  final int credits;

  /// Owner-approved KRW price — a display fallback; the store price wins.
  final int approvedKrw;

  /// One 1-Credit unit = one first review + one re-review of the same answer
  /// (re-review window 14 days). Shown concisely on the card.
  String get answerSummary =>
      '답안 $credits개 첨삭 (답안당 재첨삭 1회 포함)';
}

/// The launch catalog. 20-Credit is intentionally excluded this release.
const creditProducts = <CreditProduct>[
  CreditProduct(id: 'com.legendstudy.essay.credit1', credits: 1, approvedKrw: 4900),
  CreditProduct(id: 'com.legendstudy.essay.credit3', credits: 3, approvedKrw: 11900),
  CreditProduct(id: 'com.legendstudy.essay.credit5', credits: 5, approvedKrw: 17900),
  CreditProduct(id: 'com.legendstudy.essay.credit10', credits: 10, approvedKrw: 29900),
];

/// All store product identifiers to query, as a set.
Set<String> get creditProductIds => {for (final p in creditProducts) p.id};

/// Resolve a store product id back to its approved catalog entry, or null for
/// an id the app does not recognise (never grant for an unknown product).
CreditProduct? creditProductForId(String id) {
  for (final p in creditProducts) {
    if (p.id == id) return p;
  }
  return null;
}

/// Approved KRW formatted as e.g. "4,900원" (display fallback only).
String formatKrw(int won) {
  final s = won.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$buf원';
}
