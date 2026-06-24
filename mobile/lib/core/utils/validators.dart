// coverage:ignore-file

/// Input validation utilities
class Validators {
  /// Validates a full name
  /// Returns an error message if invalid, otherwise null
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    // Check if name contains at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Name must contain at least one letter';
    }
    return null;
  }

  /// Validates a phone number
  /// Returns an error message if invalid, otherwise null
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional in some places, so we handle empty separately if needed
    }

    final trimmed = value.trim();

    // Check if it's just a '+'
    if (trimmed == '+') {
      return 'Please enter a valid phone number';
    }

    // Remove common formatting characters for length check
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return 'Please enter at least one digit';
    }

    if (digitsOnly.length < 7) {
      return 'Phone number is too short';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }

    return null;
  }

  /// Validates an email address
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates a password
  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates password confirmation
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
