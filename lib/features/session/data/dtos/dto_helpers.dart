/// Parsing helpers for Appwrite document data maps and list elements.
extension DtoMap on Map<String, dynamic> {
  /// Returns the value at [key] as [T], throwing a [FormatException] with
  /// full document context if the value is absent or the wrong type.
  T require<T>(String key, String docId, String collection) {
    final value = this[key];
    if (value is! T) {
      throw FormatException(
        '$collection doc $docId: expected $T for "$key", '
        'got ${value.runtimeType} ($value)',
      );
    }
    return value;
  }

  /// Parses [key] as an enum from [values], throwing a [FormatException] with
  /// full document context if the raw string is not a recognised enum name.
  T parseEnum<T extends Enum>(
    List<T> values,
    String key,
    String docId,
    String collection,
  ) {
    final raw = require<String>(key, docId, collection);
    final match = values
        .where((enumValue) => enumValue.name == raw)
        .firstOrNull;
    if (match == null) {
      throw FormatException(
        '$collection doc $docId: unknown value "$raw" for "$key"',
      );
    }
    return match;
  }

  /// Parses a single dynamic list element as an enum value.
  ///
  /// Use this for array fields (e.g. `guessFields`) where each element must
  /// be a valid enum name. Throws a [FormatException] with document context
  /// on type mismatch or unrecognised name.
  static T parseEnumValue<T extends Enum>(
    List<T> values,
    dynamic rawValue,
    String fieldName,
    String docId,
    String collection,
  ) {
    if (rawValue is! String) {
      throw FormatException(
        '$collection doc $docId: expected String in "$fieldName", '
        'got ${rawValue.runtimeType} ($rawValue)',
      );
    }
    final match = values
        .where((enumValue) => enumValue.name == rawValue)
        .firstOrNull;
    if (match == null) {
      throw FormatException(
        '$collection doc $docId: unknown $fieldName value "$rawValue"',
      );
    }
    return match;
  }
}
