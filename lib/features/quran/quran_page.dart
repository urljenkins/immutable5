import 'package:flutter/material.dart';
import 'quran_text_service.dart';

/// A simple reader for the Qur'an text loaded from assets.
class QuranPage extends StatefulWidget {
  const QuranPage({Key? key}) : super(key: key);

  @override
  _QuranPageState createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final QuranTextService _service = QuranTextService();
  List<String>? _lines;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.getLines().then((lines) {
      setState(() {
        _lines = lines;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Qur'an")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _lines!.length,
              itemBuilder: (context, i) {
                final text = _lines![i].trim();
                if (text.isEmpty) return const SizedBox(height: 12);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              },
            ),
    );
  }
}
