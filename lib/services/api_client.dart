// HTTP client for the Shareloop Laravel API (replaces the Firebase SDKs).
//
// - Keeps the signed-in session (bearer token, uid, phone) in
//   SharedPreferences so the user stays signed in between launches.
// - watch() turns a GET endpoint into a Stream: it fetches immediately, then
//   polls every few seconds and refetches right after any write made through
//   this client — so screens built with StreamBuilder keep updating the way
//   they did with Firestore snapshots.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

import '../utils/api_exception.dart';

export '../utils/api_exception.dart';
export '../utils/json.dart';

class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient, SharedPreferences? prefs})
      : baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _http = httpClient ?? http.Client(),
        _prefs = prefs;

  final String baseUrl;
  final http.Client _http;
  SharedPreferences? _prefs;

  static const _tokenKey = 'api_token';
  static const _uidKey = 'api_uid';
  static const _phoneKey = 'api_phone';
  static const _timeout = Duration(seconds: 20);

  String? _token;
  String? uid;
  String? phone;

  final _changes = StreamController<void>.broadcast();

  bool get hasSession => _token != null && uid != null;

  /// Loads a saved session (call once in main()).
  Future<void> restoreSession() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    uid = prefs.getString(_uidKey);
    phone = prefs.getString(_phoneKey);
  }

  Future<void> saveSession({required String token, required String uid, String? phone}) async {
    _token = token;
    this.uid = uid;
    this.phone = phone;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_uidKey, uid);
    if (phone != null) await prefs.setString(_phoneKey, phone);
  }

  Future<void> clearSession() async {
    _token = null;
    uid = null;
    phone = null;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_uidKey);
    await prefs.remove(_phoneKey);
  }

  /// Absolute URL for an API path such as `/items`.
  Uri uri(String path, [Map<String, String?>? query]) {
    final q = <String, String>{
      for (final e in (query ?? const <String, String?>{}).entries)
        if (e.value != null) e.key: e.value!,
    };
    return Uri.parse('$baseUrl$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Map<String, String> _headers({bool json = true}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ---------- requests ----------

  Future<dynamic> get(String path, {Map<String, String?>? query}) async =>
      _decode(await _send(() => _http.get(uri(path, query), headers: _headers(json: false))));

  /// GET that answers null instead of throwing on 404.
  Future<dynamic> getOrNull(String path, {Map<String, String?>? query}) async {
    try {
      return await get(path, query: query);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  Future<dynamic> post(String path, [Object? body]) => _write(
      () => _http.post(uri(path), headers: _headers(), body: jsonEncode(body ?? const {})));

  Future<dynamic> patch(String path, [Object? body]) => _write(
      () => _http.patch(uri(path), headers: _headers(), body: jsonEncode(body ?? const {})));

  /// Multipart file upload (photos).
  Future<dynamic> upload(
    String path, {
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
  }) {
    return _write(() async {
      final request = http.MultipartRequest('POST', uri(path))
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(fields)
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      return http.Response.fromStream(await _http.send(request));
    });
  }

  Future<dynamic> _write(Future<http.Response> Function() send) async {
    final result = _decode(await _send(send));
    notifyChanged();
    return result;
  }

  Future<http.Response> _send(Future<http.Response> Function() send) async {
    final response = await send().timeout(_timeout);
    if (response.statusCode == 401 && _token != null) {
      await clearSession(); // token revoked or expired
    }
    return response;
  }

  dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    dynamic body;
    try {
      body = text.isEmpty ? null : jsonDecode(text);
    } catch (_) {
      body = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    final map = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    throw ApiException(
      response.statusCode,
      map['code'] as String? ?? 'http-${response.statusCode}',
      map['message'] as String? ?? 'Request failed (${response.statusCode}).',
    );
  }

  // ---------- live data ----------

  /// Tells every watch() stream to refetch now (called after each write).
  void notifyChanged() => _changes.add(null);

  /// A Stream for GET [path]: emits when the JSON changes. 404 → mapper(null).
  /// Like Firestore snapshots, it can be listened to more than once; every
  /// listener gets its own polling loop.
  Stream<T> watch<T>(
    String path,
    T Function(dynamic json) mapper, {
    Map<String, String?>? query,
    Duration every = const Duration(seconds: 6),
  }) {
    return Stream<T>.multi((controller) {
      Timer? timer;
      StreamSubscription<void>? changeSub;
      String? lastBody;
      var busy = false;
      var again = false;
      var closed = false;

      Future<void> tick() async {
        if (busy) {
          again = true;
          return;
        }
        busy = true;
        try {
          do {
            again = false;
            final response = await _send(
                () => _http.get(uri(path, query), headers: _headers(json: false)));
            if (closed) return;
            final text = utf8.decode(response.bodyBytes);
            if (response.statusCode == 404) {
              if (lastBody != '404') controller.add(mapper(null));
              lastBody = '404';
            } else {
              final decoded = _decode(response);
              if (text != lastBody) controller.add(mapper(decoded));
              lastBody = text;
            }
          } while (again && !closed);
        } catch (e, st) {
          // Only surface errors before the first value; later blips keep the old data.
          if (lastBody == null && !closed) controller.addError(e, st);
          if (kDebugMode) debugPrint('watch $path failed: $e');
        } finally {
          busy = false;
        }
      }

      tick();
      timer = Timer.periodic(every, (_) => tick());
      changeSub = _changes.stream.listen((_) => tick());
      controller.onCancel = () {
        closed = true;
        timer?.cancel();
        changeSub?.cancel();
      };
    });
  }
}
