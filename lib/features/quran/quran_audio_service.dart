import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QuranReciter {
  final String id;
  final String name;

  const QuranReciter({required this.id, required this.name});
}

class QuranAudioService {
  // A curated list of popular reciters.
  // The API supports many, but we'll start with a few high-quality ones.
  static const List<QuranReciter> availableReciters = [
    QuranReciter(id: 'ar.alafasy', name: 'Mishary Rashid Alafasy'),
    QuranReciter(id: 'ar.abdulbasitmurattal', name: 'Abdul Basit (Murattal)'),
    QuranReciter(id: 'ar.minshawi', name: 'Muhammad Siddiq Al-Minshawi'),
    QuranReciter(id: 'ar.husary', name: 'Mahmoud Khalil Al-Husary'),
    QuranReciter(id: 'ar.mahermuaiqly', name: 'Maher Al Muaiqly'),
  ];

  /// Fetches audio data for a full Surah.
  /// Returns a list of audio URLs, where index i corresponds to verse i.
  Future<List<String>> getSurahAudioData(
    int surahNumber,
    String reciterId,
  ) async {
    final url = Uri.parse(
      'https://api.alquran.cloud/v1/surah/$surahNumber/$reciterId',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'quran_audio_${surahNumber}_$reciterId';

      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try {
          final list = json.decode(cached) as List;
          return list.map((e) => e as String).toList();
        } catch (_) {
          // Fallback to fetch if corrupted
        }
      }

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final ayahs = data['data']['ayahs'] as List;

        // Extract audio URLs from the response
        final urls = ayahs
            .map((ayah) => (ayah as Map<String, dynamic>)['audio'] as String)
            .toList();

        await prefs.setString(cacheKey, json.encode(urls));
        return urls;
      } else {
        throw Exception('Failed to load audio data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching audio data: $e');
    }
  }
}
