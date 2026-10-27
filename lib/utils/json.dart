// JSON helpers shared by the models and API services.

/// ISO-8601 string from the API → local DateTime (null if missing).
DateTime? parseDate(dynamic value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// A JSON array of objects.
List<Map<String, dynamic>> jsonList(dynamic value) =>
    (value as List? ?? const []).cast<Map<String, dynamic>>();
