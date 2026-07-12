import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Thrown for any non-2xx response; carries the server's error message
/// when the backend returned one (it always sends {"error": "..."}).
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

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

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

  /// Cold-start friendly health check. Free-tier servers can take
  /// 30-50s to wake up, so callers should show a patient loading state.
  Future<bool> ping() async {
    try {
      final res = await http
          .get(_uri('/health'))
          .timeout(const Duration(seconds: 55));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<Profile> saveProfile(Profile profile) async {
    final res = await http.post(
      _uri('/api/profiles'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile.toJson()),
    );
    final json = _decode(res);
    final saved = json['profile'] as Map<String, dynamic>? ?? json;
    return Profile.fromJson({...saved, 'id': saved['id'] ?? json['id']});
  }

  Future<Profile> getProfile(String id) async {
    final res = await http.get(_uri('/api/profiles/$id'));
    return Profile.fromJson(_decode(res));
  }

  Future<void> deleteProfile(String id) async {
    final res = await http.delete(_uri('/api/profiles/$id'));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _decode(res);
    }
  }

  Future<List<MatchResult>> getMatches(String profileId, {int topK = 10}) async {
    final res = await http.get(_uri('/api/profiles/$profileId/matches', {'top_k': topK}));
    final body = res.body.isEmpty ? '[]' : res.body;
    final decoded = jsonDecode(body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = decoded is Map && decoded['error'] != null
          ? decoded['error'].toString()
          : 'Could not load matches (${res.statusCode}).';
      throw ApiException(res.statusCode, message);
    }
    final list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return list.map((e) => MatchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MatchDetail> compare(String profileId, String candidateId) async {
    final res = await http.get(_uri('/api/profiles/$profileId/compare/$candidateId'));
    return MatchDetail.fromJson(_decode(res));
  }

  Future<PersonalitySnapshot> assess(Map<String, int> traits) async {
    final res = await http.post(
      _uri('/api/assessment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(traits),
    );
    return PersonalitySnapshot.fromJson(_decode(res));
  }
}
