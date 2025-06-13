import 'dart:convert';
import 'package:http/http.dart' as http;

class SpoonacularApi {
  static final String _apiKey = '1c1364d7d3b24ef78036ad2c6f4d54af';
  static const String _baseUrl = 'https://api.spoonacular.com';

  static Future<Map<String, dynamic>> searchRecipes(
    String query, {
    int offset = 0,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/recipes/complexSearch?query=${Uri.encodeQueryComponent(query)}&apiKey=$_apiKey&number=30&offset=$offset',
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

    return jsonBody;
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
