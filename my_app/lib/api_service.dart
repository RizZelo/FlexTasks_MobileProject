import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.56.1:3000";
  // On real device: replace with your PC IP

  static Future<String> getMessage() async {
    final response = await http.get(Uri.parse("$baseUrl/"));

    if (response.statusCode == 200) {
      return json.decode(response.body)['message'];
    } else {
      throw Exception("Failed to load message");
    }
  }
}
