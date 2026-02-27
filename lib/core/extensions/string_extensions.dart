import 'package:flutter_multi_formatter/formatters/formatter_utils.dart';

/// Extension on `String` to provide additional utility methods.
extension StringExt on String {
  /// Returns the initials of the string.
  ///
  /// If the string is empty, returns an empty string.
  /// Otherwise, returns the first character of up to the first two words,
  /// converted to uppercase.
  String get initials {
    if (isEmpty) return '';
    final words = trim().split(' ');

    final initials = StringBuffer();

    for (var i = 0; i < words.length && i < 2; i++) {
      initials.write(words[i][0]);
    }

    return initials.toString().toUpperCase();
  }

  /// Returns a string containing only the numeric characters from the
  /// original string.
  ///
  /// Allows periods to be included in the numeric string.
  String get onlyNumbers {
    return toNumericString(this, allowPeriod: true);
  }

  /// Capitalizes the first letter of the string.
  ///
  /// If the string is empty or contains only whitespace, returns the original
  /// string. Otherwise, returns the string with the first character in
  /// uppercase and the rest in lowercase.
  String get capitalize {
    if (trim().isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Converts the string to title case.
  ///
  /// If the string is empty or contains only whitespace, returns the
  /// original string.
  /// Otherwise, capitalizes the first letter of each word in the string.
  String get titleCase {
    if (trim().isEmpty) return this;
    return split(' ').map<String>((e) => e.capitalize).toList().join(' ');
  }

  /// Converts the string to snake_case.
  ///
  /// Replaces each uppercase letter with an underscore followed by the
  /// lowercase letter, and removes any leading underscores.
  String get snakeCase {
    return replaceAllMapped(
      RegExp('([A-Z])'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceAll(RegExp('^_'), '');
  }
}
