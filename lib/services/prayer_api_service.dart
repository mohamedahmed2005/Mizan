import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PrayerApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1/timingsByCity';
  static const String _city = 'Cairo';
  static const String _country = 'Egypt';
  static const int _method = 5; // Egyptian General Authority of Survey

  /// Fetches prayer times from Aladhan API and returns a list of formatted 12-hour strings
  /// in the order: Fajr, Dhuhr, Asr, Maghrib, Isha
  static Future<List<String>?> fetchPrayerTimes() async {
    try {
      final url = Uri.parse(
          '$_baseUrl?city=$_city&country=$_country&method=$_method');
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
