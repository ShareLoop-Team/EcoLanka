// Error type for failed API calls (shared by services, controllers and views).

/// An error answered by the API: {"message": "...", "code": "..."}.
class ApiException implements Exception {
  ApiException(this.statusCode, this.code, this.message);

  final int statusCode;
  final String code;
  final String message;

  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isUnauthenticated => statusCode == 401;

  @override
  String toString() => message; // shown in snack bars as-is
}
