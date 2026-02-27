import 'dart:convert';
import 'package:http/http.dart' as http;

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
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> ayahs = data['data']['ayahs'];

        // Extract audio URLs from the response
        // The API returns 'audio' field for each ayah
        return ayahs.map<String>((ayah) => ayah['audio'] as String).toList();
      } else {
        throw Exception('Failed to load audio data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching audio data: $e');
    }
  }
}
