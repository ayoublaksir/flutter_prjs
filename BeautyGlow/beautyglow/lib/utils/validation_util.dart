/// Utility class for form validation
class ValidationUtil {
  ValidationUtil._();

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    // Check for valid characters (letters, spaces, hyphens)
    final nameRegExp = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegExp.hasMatch(value)) {
      return 'Name can only contain letters, spaces, and hyphens';
    }
    return null;
  }

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate product name
  static String? validateProductName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Product name is required';
    }
    if (value.length < 2) {
      return 'Product name must be at least 2 characters';
    }
    if (value.length > 100) {
      return 'Product name must be less than 100 characters';
    }
    return null;
  }

  /// Validate brand name
  static String? validateBrandName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Brand name is required';
    }
    if (value.length < 2) {
      return 'Brand name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Brand name must be less than 50 characters';
    }
    return null;
  }

  /// Validate price
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Price is optional
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid number';
    }
    if (price < 0) {
      return 'Price cannot be negative';
    }
    if (price > 10000) {
      return 'Price seems too high';
    }
    return null;
  }

  /// Validate review text
  static String? validateReview(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Review is optional
    }
    if (value.length < 10) {
      return 'Review must be at least 10 characters';
    }
    if (value.length > 500) {
      return 'Review must be less than 500 characters';
    }
    return null;
  }

  /// Validate routine name
  static String? validateRoutineName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Routine name is required';
    }
    if (value.length < 3) {
      return 'Routine name must be at least 3 characters';
    }
    if (value.length > 50) {
      return 'Routine name must be less than 50 characters';
    }
    return null;
  }

  /// Validate step name
  static String? validateStepName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Step name is required';
    }
    if (value.length < 2) {
      return 'Step name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Step name must be less than 50 characters';
    }
    return null;
  }

  /// Validate duration
  static String? validateDuration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Duration is required';
    }
    final duration = int.tryParse(value);
    if (duration == null) {
      return 'Please enter a valid number';
    }
    if (duration < 1) {
      return 'Duration must be at least 1 minute';
    }
    if (duration > 180) {
      return 'Duration must be less than 180 minutes';
    }
    return null;
  }

  /// Validate password (if implementing auth later)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value.length > 50) {
      return 'Password must be less than 50 characters';
    }
    // Check for at least one letter and one number
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(value)) {
      return 'Password must contain at least one letter and one number';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    // Remove non-numeric characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number seems too long';
    }
    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    final urlRegExp = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegExp.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Check if string contains only letters
  static bool isAlphabetic(String value) {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(value);
  }

  /// Check if string contains only numbers
  static bool isNumeric(String value) {
    return RegExp(r'^[0-9]+$').hasMatch(value);
  }

  /// Check if string is alphanumeric
  static bool isAlphanumeric(String value) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
  }

  /// Sanitize input by removing leading/trailing whitespace
  static String sanitizeInput(String input) {
    return input.trim();
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
