import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({
    required this.description,
    required this.placeId,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
    );
  }
}

class PlaceDetails {
  final String name;
  final String address;
  final String placeId;
  final double? lat;
  final double? lng;

  PlaceDetails({
    required this.name,
    required this.address,
    required this.placeId,
    this.lat,
    this.lng,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    final geometry = result['geometry'];
    final location = geometry?['location'];
    
    return PlaceDetails(
      name: result['name'] ?? '',
      address: result['formatted_address'] ?? '',
      placeId: result['place_id'] ?? '',
      lat: location?['lat']?.toDouble(),
      lng: location?['lng']?.toDouble(),
    );
  }
}

class ApiService {
  static const String baseUrl = "http://10.0.2.2:3000";
  // For Android Emulator: 10.0.2.2:3000
  // For iOS Simulator: localhost:3000
  // For Real Device: Your computer's IP address

  static Future<String> getMessage() async {
    final response = await http.get(Uri.parse("$baseUrl/"));

    if (response.statusCode == 200) {
      return json.decode(response.body)['message'];
    } else {
      throw Exception("Failed to load message");
    }
  }

  // Get place autocomplete suggestions
  static Future<List<PlacePrediction>> getPlacePredictions(String input) async {
    if (input.isEmpty) return [];

    try {
      final url = Uri.parse("$baseUrl/api/places/autocomplete")
          .replace(queryParameters: {'input': input});
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = (data['predictions'] as List)
              .map((pred) => PlacePrediction.fromJson(pred))
              .toList();
          return predictions;
        }
        return [];
      } else {
        print('Failed to fetch places: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching place predictions: $e');
      return [];
    }
  }

  // Get place details by place ID
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse("$baseUrl/api/places/details")
          .replace(queryParameters: {'place_id': placeId});
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data);
        }
        return null;
      } else {
        print('Failed to fetch place details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching place details: $e');
      return null;
    }
  }
}
