import 'dart:convert';
import 'package:http/http.dart' as http;

// your Spring Boot server address
// same as API_BASE_URL in React
const String baseUrl = 'http://localhost:8081/api';

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
    final response = await http.get(
      Uri.parse('$baseUrl/farms/$farmId/plots'),
    );

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
}