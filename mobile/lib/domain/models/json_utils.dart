/// Small helpers for manual, type-safe JSON parsing.
///
/// Every reader throws [FormatException] with the key name instead of an
/// opaque TypeError, so bad backend payloads are easy to diagnose.
library;

double readNum(Map<String, dynamic> json, String key) => switch (json[key]) {
      num v => v.toDouble(),
      _ => throw FormatException('Expected number for "$key"', json[key]),
    };

double? readNumOrNull(Map<String, dynamic> json, String key) => switch (json[key]) {
      null => null,
      num v => v.toDouble(),
      _ => throw FormatException('Expected number or null for "$key"', json[key]),
    };

int readInt(Map<String, dynamic> json, String key) => switch (json[key]) {
      int v => v,
      _ => throw FormatException('Expected int for "$key"', json[key]),
    };

String readString(Map<String, dynamic> json, String key) => switch (json[key]) {
      String v => v,
      _ => throw FormatException('Expected string for "$key"', json[key]),
    };

String? readStringOrNull(Map<String, dynamic> json, String key) => switch (json[key]) {
      null => null,
      String v => v,
      _ => throw FormatException('Expected string or null for "$key"', json[key]),
    };

DateTime readDate(Map<String, dynamic> json, String key) =>
    DateTime.parse(readString(json, key)).toUtc();

DateTime? readDateOrNull(Map<String, dynamic> json, String key) {
  final s = readStringOrNull(json, key);
  return s == null ? null : DateTime.parse(s).toUtc();
}

List<String> readStringList(Map<String, dynamic> json, String key) => switch (json[key]) {
      null => const [],
      List<dynamic> v => v.cast<String>(),
      _ => throw FormatException('Expected list for "$key"', json[key]),
    };

T readEnum<T extends Enum>(Map<String, dynamic> json, String key, List<T> values) {
  final raw = readString(json, key);
  for (final v in values) {
    if (v.name.toUpperCase() == raw.replaceAll('_', '').toUpperCase()) return v;
  }
  throw FormatException('Unknown value for "$key"', raw);
}

T? readEnumOrNull<T extends Enum>(Map<String, dynamic> json, String key, List<T> values) =>
    json[key] == null ? null : readEnum(json, key, values);

/// Converts an enum back to the backend's SCREAMING_SNAKE_CASE.
String enumToJson(Enum e) =>
    e.name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]}').toUpperCase();
