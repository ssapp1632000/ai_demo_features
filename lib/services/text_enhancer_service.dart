import 'dart:convert';
import 'package:http/http.dart' as http;

class TextEnhancerService {
  // Base URL for the API - adjust if needed
  static const String baseUrl =
      'https://ai.ssapp.site';
  static const String enhanceEndpoint =
      '/api/v1/text-enhancer/enhance';

  /// Enhances the provided text using the API
  ///
  /// [text] - The text to be enhanced
  ///
  /// Returns the enhanced text on success
  /// Throws an exception on failure
  static Future<String> enhanceText(String text) async {
    try {
      final url = Uri.parse('$baseUrl$enhanceEndpoint');

      // Prepare request body
      final requestBody = jsonEncode({
        "enhancement_type": "grammar",
        "target_tone": "formal",
        "text": text,
      });

      // Make POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      // Check response status
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract enhanced text from response
        // Adjust the key based on actual API response structure
        if (responseData.containsKey('enhanced_text')) {
          return responseData['enhanced_text'] as String;
        } else if (responseData.containsKey('result')) {
          return responseData['result'] as String;
        } else if (responseData.containsKey('text')) {
          return responseData['text'] as String;
        } else if (responseData.containsKey('output')) {
          return responseData['output'] as String;
        } else {
          // If the response structure is different, return the whole response as string
          return responseData.toString();
        }
      } else if (response.statusCode == 422) {
        throw Exception(
          'Invalid request: ${response.body}',
        );
      } else if (response.statusCode == 500) {
        throw Exception(
          'Server error: Failed to enhance text',
        );
      } else {
        throw Exception(
          'Failed to enhance text: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error enhancing text: $e');
    }
  }
}
