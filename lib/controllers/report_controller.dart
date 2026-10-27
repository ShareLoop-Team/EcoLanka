// ReportController — report users / items; admin review (Trust & Safety).

import '../models/report.dart';
import '../repositories/repositories.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';

class ReportController {
  ReportController({required ReportRepository reports, required AuthRepository auth})
      : _reports = reports,
        _auth = auth;

  final ReportRepository _reports;
  final AuthRepository _auth;

  /// Returns false if this user already reported this target.
  Future<bool> submit({
    required String targetType, // item | user
    required String targetId,
    required String reason,
    String details = '',
  }) {
    final uid = _auth.currentUid;
    if (uid == null) throw StateError('Not signed in.');
    if (!ReportReasons.labels.containsKey(reason)) throw StateError('Pick a reason.');
    final error = Validators.reportDetails(details);
    if (error != null) throw StateError(error);

    return _reports.create('${targetType}_${targetId}_$uid', {
      'reporterId': uid,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'details': details.trim(),
      'evidence': <String>[],
      'status': 'open',
    });
  }

  /// Admin: all reports, open ones first.
  Stream<List<Report>> allReports() => _reports.allReports().map((list) => list
    ..sort((a, b) {
      final aOpen = a.status == 'open' ? 0 : 1;
      final bOpen = b.status == 'open' ? 0 : 1;
      if (aOpen != bOpen) return aOpen - bOpen;
      return (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());
    }));

  Future<void> setStatus(String reportId, String status) =>
      _reports.setStatus(reportId, status);
}
