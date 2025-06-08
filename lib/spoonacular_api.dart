import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SpoonacularApi {
  static final String _apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.spoonacular.com';

  static Future<List<dynamic>> searchRecipes(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/recipes/complexSearch?query=${Uri.encodeQueryComponent(query)}&apiKey=$_apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to search recipes (status code: ${response.statusCode})',
      );
    }

    final Map<String, dynamic> jsonBody = json.decode(response.body);
    if (!jsonBody.containsKey('results')) {
      throw Exception('Unexpected response format: "results" key not found.');
    }

    return jsonBody['results'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getRecipeInformation(int id) async {
    final uri = Uri.parse(
      '$_baseUrl/recipes/$id/information?includeNutrition=true&apiKey=$_apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch recipe details (status code: ${response.statusCode})',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }
}
