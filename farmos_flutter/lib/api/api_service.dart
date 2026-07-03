import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const String _defaultBaseUrl = 'http://localhost:8081/api';

const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: _defaultBaseUrl,
);

class ApiService {
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(body['error'] ?? 'Login failed');
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(body['error'] ?? 'Register failed');
  }

  static Future<List<dynamic>> getFarms(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/farms?userId=$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load farms');
  }

  static Future<Map<String, dynamic>> createFarm(
    int userId,
    Map<String, dynamic> farm,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/farms?userId=$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(farm),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to create farm');
  }

  static Future<Map<String, dynamic>> updateFarm(
    int id,
    Map<String, dynamic> farm,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/farms/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(farm),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update farm');
  }

  static Future<void> deleteFarm(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/farms/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete farm');
    }
  }

  static Future<List<dynamic>> getPlots(int farmId) async {
    final response = await http.get(Uri.parse('$baseUrl/farms/$farmId/plots'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load plots');
  }

  static Future<Map<String, dynamic>> createPlot(
    int farmId,
    Map<String, dynamic> plot,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/farms/$farmId/plots'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(plot),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to create plot');
  }

  static Future<Map<String, dynamic>> updatePlot(
    int farmId,
    int plotId,
    Map<String, dynamic> plot,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/farms/$farmId/plots/$plotId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(plot),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update plot');
  }

  static Future<void> deletePlot(int farmId, int plotId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/farms/$farmId/plots/$plotId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete plot');
    }
  }

  static Future<Map<String, dynamic>> detectLeafDisease(
    Uint8List imageBytes,
    String filename,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/leaf/detect'),
    );

    request.files.add(
      http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    final message = body is Map && body['error'] != null
        ? body['error']
        : 'Failed to detect leaf disease';
    throw Exception(message);
  }
}