import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PrayerApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1/timings';
  
  // Egyptian General Authority of Survey
  static const int _method = 5;

  /// Fetches prayer times from Aladhan API. If lat/lng are provided, uses them.
  /// Otherwise falls back to Cairo, Egypt coordinates.
  static Future<List<String>?> fetchPrayerTimes({double? lat, double? lng}) async {
    try {
      final now = DateFormat('dd-MM-yyyy').format(DateTime.now());
      
      // Default to Cairo if no GPS provided
      final double requestLat = lat ?? 30.0444; 
      final double requestLng = lng ?? 31.2357;

      final url = Uri.parse(
          '$_baseUrl/$now?latitude=$requestLat&longitude=$requestLng&method=$_method');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];

        // Extract the 5 obligatory prayers
        final List<String> rawTimes = [
          timings['Fajr'],
          timings['Dhuhr'],
          timings['Asr'],
          timings['Maghrib'],
          timings['Isha'],
        ];

        // Convert from 24h format "HH:mm" to 12h format "h:mm a"
        final List<String> formattedTimes = rawTimes.map((time) {
          final parsedTime = DateFormat('HH:mm').parse(time);
          return DateFormat('h:mm a').format(parsedTime);
        }).toList();

        return formattedTimes;
      }
    } catch (e) {
      debugPrint('Error fetching prayer times: $e');
    }
    return null;
  }
}
