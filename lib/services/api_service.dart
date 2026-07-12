import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Thrown for any non-2xx response, or for a network-level failure
/// (no connection, timeout). `statusCode` is 0 for network-level
/// failures so callers can distinguish "server said no" from
/// "couldn't reach the server" if they need to.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService({this.baseUrl = 'https://vibe-connect-si0i.onrender.com'});

  final String baseUrl;

  static const _defaultTimeout = Duration(seconds: 20);
  // Cold start on the free tier can take 30-50s.
  static const _coldStartTimeout = Duration(seconds: 55);

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  /// Wraps every request so network failures surface as a friendly
  /// [ApiException] instead of an uncaught SocketException/TimeoutException.
  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on TimeoutException {
      throw ApiException(0, 'The server is taking too long to respond. Please try again.');
    } on SocketException {
      throw ApiException(0, 'No internet connection. Check your network and try again.');
    } on HandshakeException {
      throw ApiException(0, 'Couldn\'t establish a secure connection. Please try again.');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Network error: ${e.message}');
    } on FormatException {
      throw ApiException(0, 'Received an unexpected response from the server.');
    }
  }

  Future<http.Response> _get(Uri uri, {Duration? timeout}) =>
      _send(() => http.get(uri).timeout(timeout ?? _defaultTimeout));

  Future<http.Response> _post(Uri uri, {Object? body, Duration? timeout}) => _send(() => http
      .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
      .timeout(timeout ?? _defaultTimeout));

  Future<http.Response> _delete(Uri uri, {Duration? timeout}) =>
      _send(() => http.delete(uri).timeout(timeout ?? _defaultTimeout));

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty ? '{}' : res.body;
    final decoded = jsonDecode(body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = decoded is Map && decoded['error'] != null
          ? decoded['error'].toString()
          : 'Something went wrong (${res.statusCode}).';
      throw ApiException(res.statusCode, message);
    }
    return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
  }

  List<dynamic> _decodeList(http.Response res, {String friendlyAction = 'load data'}) {
    final body = res.body.isEmpty ? '[]' : res.body;
    final decoded = jsonDecode(body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = decoded is Map && decoded['error'] != null
          ? decoded['error'].toString()
          : 'Could not $friendlyAction (${res.statusCode}).';
      throw ApiException(res.statusCode, message);
    }
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
    if (decoded is Map && decoded['profiles'] is List) return decoded['profiles'] as List;
    return const [];
  }

  /// Cold-start friendly health check. Free-tier servers can take
  /// 30-50s to wake up, so callers should show a patient loading state.
  Future<bool> ping() async {
    try {
      final res = await http.get(_uri('/health')).timeout(_coldStartTimeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<Profile> saveProfile(Profile profile) async {
    final res = await _post(_uri('/api/profiles'), body: jsonEncode(profile.toJson()));
    final json = _decode(res);
    final saved = json['profile'] as Map<String, dynamic>? ?? json;
    return Profile.fromJson({...saved, 'id': saved['id'] ?? json['id']});
  }

  Future<Profile> getProfile(String id) async {
    final res = await _get(_uri('/api/profiles/$id'));
    return Profile.fromJson(_decode(res));
  }

  Future<void> deleteProfile(String id) async {
    final res = await _delete(_uri('/api/profiles/$id'));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _decode(res);
    }
  }

  Future<List<MatchResult>> getMatches(String profileId, {int topK = 10}) async {
    final res = await _get(_uri('/api/profiles/$profileId/matches', {'top_k': topK}));
    final list = _decodeList(res, friendlyAction: 'load matches');
    return list.map((e) => MatchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MatchDetail> compare(String profileId, String candidateId) async {
    final res = await _get(_uri('/api/profiles/$profileId/compare/$candidateId'));
    return MatchDetail.fromJson(_decode(res));
  }

  Future<PersonalitySnapshot> assess(Map<String, int> traits) async {
    final res = await _post(_uri('/api/assessment'), body: jsonEncode(traits));
    return PersonalitySnapshot.fromJson(_decode(res));
  }

  /// Admin only: every profile in the system. There is no
  /// pagination on the backend today, so this pulls the full set —
  /// fine for a small admin tool, worth revisiting if the user base
  /// grows large.
  Future<List<Profile>> getAllProfiles() async {
    final res = await _get(_uri('/api/profiles'));
    final list = _decodeList(res, friendlyAction: 'load profiles');
    return list.map((e) => Profile.fromJson(e as Map<String, dynamic>)).toList();
  }
}
