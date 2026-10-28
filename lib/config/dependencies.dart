// Composition root — the ONE place where concrete implementations are chosen
// and injected into controllers (Dependency Inversion).
//
// Views talk to controllers:      Dependencies.items.availableItems()
// Controllers talk to interfaces: ItemRepository, AuthRepository, …
// Swap the API services for fakes in tests by passing your own repositories to init().

import '../controllers/auth_controller.dart';
import '../controllers/item_controller.dart';
import '../controllers/need_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/report_controller.dart';
import '../controllers/request_controller.dart';
import '../controllers/review_controller.dart';
import '../controllers/user_controller.dart';
import '../repositories/repositories.dart';
import '../config/app_config.dart';
import '../services/api_auth_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../services/database_service.dart';
import '../services/item_service.dart';
import '../services/location_service.dart';
import '../services/need_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../services/request_service.dart';
import '../services/review_service.dart';

class Dependencies {
  Dependencies._();

  static late AuthController auth;
  static late UserController users;
  static late ItemController items;
  static late NeedController needs;
  static late RequestController requests;
  static late ReviewController reviews;
  static late ReportController reports;
  static late NotificationController notifications;

  /// The HTTP client every API service shares (session + live refresh).
  static late ApiClient api;

  /// Call once in main() after `api.restoreSession()`.
  static void init({
    ApiClient? apiClient,
    AuthRepository? authRepository,
    UserRepository? userRepository,
    ItemRepository? itemRepository,
    NeedRepository? needRepository,
    RequestRepository? requestRepository,
    ReviewRepository? reviewRepository,
    ReportRepository? reportRepository,
    NotificationRepository? notificationRepository,
    ImageStorage? imageStorage,
    LocationProvider? locationProvider,
  }) {
    final client = api = apiClient ?? ApiClient();
    final authRepo = authRepository ??
        (AppConfig.useFirebaseAuth ? FirebaseAuthService(client) : ApiAuthService(client));
    final userRepo = userRepository ?? ApiUserService(client);
    final itemRepo = itemRepository ?? ApiItemService(client);
    final needRepo = needRepository ?? ApiNeedService(client);
    final images = imageStorage ?? ApiImageStorage(client);

    auth = AuthController(authRepo);
    users = UserController(
      users: userRepo,
      auth: authRepo,
      images: images,
      location: locationProvider ?? GeolocatorLocationService(),
    );
    items = ItemController(
      items: itemRepo,
      needs: needRepo,
      images: images,
      auth: authRepo,
    );
    needs = NeedController(needs: needRepo, auth: authRepo);
    requests = RequestController(
      requests: requestRepository ?? ApiRequestService(client),
      users: userRepo,
      auth: authRepo,
    );
    reviews = ReviewController(
      reviews: reviewRepository ?? ApiReviewService(client),
      auth: authRepo,
    );
    reports = ReportController(
      reports: reportRepository ?? ApiReportService(client),
      auth: authRepo,
    );
    notifications = NotificationController(
      notifications: notificationRepository ?? ApiNotificationService(client),
      auth: authRepo,
    );
  }
}
