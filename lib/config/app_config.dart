// App-wide backend configuration.
// (The theme lives in theme.dart; this file used to hold a duplicate copy of it.)

class AppConfig {
  AppConfig._();

  /// Firebase project (see backend/.firebaserc).
  static const String firebaseProjectId = 'shareloop-c2157';

  /// Cloudinary image hosting (free plan, replaces Firebase Storage).
  /// Set up: docs/INFRA.md → "Cloudinary". Put your cloud name here.
  static const String cloudinaryCloudName = 'REPLACE_WITH_CLOUD_NAME';
  static const String cloudinaryUploadPreset = 'shareloop_unsigned';

  /// Max photos per item (also enforced in firestore.rules).
  static const int maxItemImages = 5;
}
