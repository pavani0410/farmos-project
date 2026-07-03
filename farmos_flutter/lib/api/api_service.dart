import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String _defaultBaseUrl = 'http://localhost:8081/api';

const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: _defaultBaseUrl,
);
class ApiService {
  // GET /api/farms
  static Future<List<dynamic>> getFarms() async {
    final response = await http.get(Uri.parse('$baseUrl/farms'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load farms');
  }

  // POST /api/farms
  static Future<Map<String, dynamic>> createFarm(
    Map<String, dynamic> farm,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/farms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(farm),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to create farm');
  }

  // PUT /api/farms/:id
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

  // DELETE /api/farms/:id
  static Future<void> deleteFarm(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/farms/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete farm');
    }
  }

  // GET /api/farms/:farmId/plots
  static Future<List<dynamic>> getPlots(int farmId) async {
    final response = await http.get(Uri.parse('$baseUrl/farms/$farmId/plots'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load plots');
  }

  // POST /api/farms/:farmId/plots
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

  // PUT /api/farms/:farmId/plots/:plotId
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

  // DELETE /api/farms/:farmId/plots/:plotId
  static Future<void> deletePlot(int farmId, int plotId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/farms/$farmId/plots/$plotId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete plot');
    }
  }

  // POST /api/leaf/detect
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
