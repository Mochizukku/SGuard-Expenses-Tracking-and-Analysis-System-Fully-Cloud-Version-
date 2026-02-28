import 'dart:convert';

import 'package:http/http.dart' as http;

/// Simple FastAPI gateway wrapper. Point [baseUrl] to your FastAPI host.
class FastApiGateway {
  FastApiGateway({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const baseUrl = 'https://your-gateway.example.com/api';

  Future<Map<String, dynamic>> fetchProfileSummary(String userId) async {
    final uri = Uri.parse('$baseUrl/profile-summary/$userId');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw http.ClientException('Failed to load profile summary', uri);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
