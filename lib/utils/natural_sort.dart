final RegExp _digitsPattern = RegExp(r'\d+');

/// Case-insensitive "natural" comparator for dropdown/list labels: runs of
/// digits are compared numerically wherever they appear (so "Year 2" sorts
/// before "Year 10"), and everything else is compared as plain text. This
/// gives alphabetical ordering for name-like labels and numeric ordering
/// for year/date/number-like labels with a single comparator.
int naturalCompare(String a, String b) {
  final aTokens = _tokenize(a);
  final bTokens = _tokenize(b);
  final len = aTokens.length < bTokens.length ? aTokens.length : bTokens.length;
  for (var i = 0; i < len; i++) {
    final at = aTokens[i];
    final bt = bTokens[i];
    final aNum = int.tryParse(at);
    final bNum = int.tryParse(bt);
    int cmp;
    if (aNum != null && bNum != null) {
      cmp = aNum.compareTo(bNum);
    } else {
      cmp = at.compareTo(bt);
    }
    if (cmp != 0) return cmp;
  }
  return aTokens.length.compareTo(bTokens.length);
}

/// Splits into alternating digit/non-digit chunks, lowercased.
List<String> _tokenize(String s) {
  final lower = s.trim().toLowerCase();
  final tokens = <String>[];
  var last = 0;
  for (final m in _digitsPattern.allMatches(lower)) {
    if (m.start > last) tokens.add(lower.substring(last, m.start));
    tokens.add(m.group(0)!);
    last = m.end;
  }
  if (last < lower.length) tokens.add(lower.substring(last));
  return tokens;
}

/// Sorts [items] in place by [naturalCompare] applied to [labelOf], and
/// returns the same list for convenient chaining.
List<T> sortNatural<T>(List<T> items, String Function(T) labelOf) {
  items.sort((a, b) => naturalCompare(labelOf(a), labelOf(b)));
  return items;
}
