import 'dart:convert';

import 'package:http/http.dart' as http;

/// JSON-over-HTTP transport to the Vercel function. Knows nothing about the game.
class GameApi {
  GameApi(this.endpoint);
  final Uri endpoint;
  final _client = http.Client();

  /// Returns the decoded reply (including `{error}` replies).
  /// Throws on network failure or a non-JSON response.
  Future<Map<String, dynamic>> send(Map<String, Object?> body) async {
    final res = await _client
        .post(endpoint,
            headers: {'content-type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}
