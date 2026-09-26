class KVDateUtils {
  /// Parses Microsoft .NET JSON date formats like "/Date(1790361000000)/"
  static DateTime? parseDotNetDate(String? dateStr, {bool isUtc = false}) {
    if (dateStr == null || !dateStr.contains('/Date(')) return null;
    final match = RegExp(r'/Date\((-?\d+)\)/').firstMatch(dateStr);
    if (match != null && match.groupCount >= 1) {
      final timestamp = int.tryParse(match.group(1)!);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: isUtc);
      }
    }
    return null;
  }
}
