// API implementation of ReportRepository — /reports (admins read / update).

import '../models/report.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

class ApiReportService implements ReportRepository {
  ApiReportService(this._api);

  final ApiClient _api;

  /// Returns false if this user already reported this target (HTTP 409).
  @override
  Future<bool> create(String reportId, Map<String, dynamic> data) async {
    try {
      await _api.post('/reports', {
        'targetType': data['targetType'],
        'targetId': data['targetId'],
        'reason': data['reason'],
        'details': data['details'] ?? '',
        'evidence': data['evidence'] ?? const <String>[],
      });
      return true;
    } on ApiException catch (e) {
      if (e.isConflict) return false;
      rethrow;
    }
  }

  @override
  Stream<List<Report>> allReports() =>
      _api.watch('/reports', (json) => jsonList(json).map(Report.fromJson).toList());

  @override
  Future<void> setStatus(String reportId, String status) =>
      _api.patch('/reports/$reportId', {'status': status});
}
