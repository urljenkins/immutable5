import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../l10n/app_localizations.dart';
import '../../shared/app_colors.dart';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage>
    with SingleTickerProviderStateMixin {
  int _count = 0;
  int _target = 100;
  bool _isVoiceEnabled = false;
  bool _isListening = false;
  int _lastRecognizedWords = 0;
  late stt.SpeechToText _speech;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _tasbihPhases = [
    {
      'arabic': 'سُبْحَانَ ٱللَّٰهِ',
      'translit': 'Subhanallah',
      'translation': 'Glory be to God.',
      'count': 33,
    },
    {
      'arabic': 'ٱلْحَمْدُ لِلَّٰهِ',
      'translit': 'Alhamdulillah',
      'translation': 'All praise is due to God.',
      'count': 33,
    },
    {
      'arabic': 'ٱللَّٰهُ أَكْبَرُ',
      'translit': 'Allahu Akbar',
      'translation': 'God is the Greatest.',
      'count': 33,
    },
    {
      'arabic': '',
      'translit':
          "La ilaha illallah wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir.",
      'translation':
          'There is no god but Allah, alone, without partner. His is the sovereignty, and His is the praise, and He is over all things competent.',
      'count': 1,
    },
  ];

  int get _phaseIndex {
    if (_count >= 100) return 4;
    if (_count < 33) return 0;
    if (_count < 66) return 1;
    if (_count < 99) return 2;
    return 3;
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _isVoiceEnabled = false;
    _pulseController.dispose();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  void _incrementCount() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _count++;
      if (_count >= _target) {
        HapticFeedback.heavyImpact();
        // Optional: Reset or just continue
        // _count = 0;
      }
    });
  }

  void _resetCount() {
    HapticFeedback.selectionClick();
    setState(() {
      _count = 0;
    });
  }

  Future<void> _toggleVoiceMode(bool enabled) async {
    if (enabled) {
      final bool available = await _speech.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() => _isListening = status == 'listening');
            if ((status == 'done' || status == 'notListening') &&
                _isVoiceEnabled) {
              // Restart listening automatically to keep it continuous
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted && _isVoiceEnabled && !_isListening) {
                  _startListening();
                }
              });
            }
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() => _isListening = false);
            if (errorNotification.errorMsg != 'error_busy') {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${errorNotification.errorMsg}')),
              );
            }
            if (_isVoiceEnabled) {
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted && _isVoiceEnabled && !_isListening) {
                  _startListening();
                }
              });
            }
          }
        },
      );

      if (available) {
        setState(() => _isVoiceEnabled = true);
        _startListening();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
        }
      }
    } else {
      setState(() {
        _isVoiceEnabled = false;
        _isListening = false;
      });
      _speech.stop();
    }
  }

  void _startListening() {
    if (_speech.isListening) return; // Prevent "error_busy"
    _lastRecognizedWords = 0;
    unawaited(_speech.listen(
      onResult: (result) {
        if (!mounted || !_isVoiceEnabled) return;

        final recognizedText = result.recognizedWords.trim();
        if (recognizedText.isEmpty) return;

        final words = recognizedText
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();

        if (words.length > _lastRecognizedWords) {
          final int diff = words.length - _lastRecognizedWords;

          // Get the current expected phrase based on phase index
          final currentPhase = _tasbihPhases[_phaseIndex];
          final expectedTranslit =
              currentPhase['translit'].toString().toLowerCase().split(' ');

          for (int i = 0; i < diff; i++) {
            // Let's do a simple check to see if the recognized words relate to the expected transliteration
            if (words.last.toLowerCase() == 'subhanallah' ||
                words.last.toLowerCase() == 'alhamdulillah' ||
                words.last.toLowerCase() == 'allahu' ||
                words.last.toLowerCase() == 'akbar' ||
                words.last.toLowerCase() == 'allah' ||
                words.last.toLowerCase() == 'la' ||
                words.last.toLowerCase() == 'ilaha' ||
                expectedTranslit
                    .any((part) => words.last.toLowerCase().contains(part))) {
              _incrementCount();
            } else {
              // Optional: we can decide to still increment or just ignore based on precise matching
              // For now, if they enable voice, we attempt to match any of the common dhikr words
              // or parts of the current expected phrase. If completely unrelated, we ignore.
            }
          }
          _lastRecognizedWords = words.length;
        }

        if (result.finalResult) {
          // The current listening session ended natively;
          // the onStatus callback handles restarting it.
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 5),
      listenOptions: stt.SpeechListenOptions(),
    ));
  }

  void _showTargetDialog() {
    unawaited(showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text(
          AppLocalizations.of(context)!.setTarget,
          style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                '33',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                setState(() => _target = 33);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                '100',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                setState(() => _target = 100);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                'Infinite (Custom)',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                // Simple custom input could be added here
                setState(() => _target = 99999);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_count / _target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.tasbih,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCount,
            tooltip: AppLocalizations.of(context)!.reset,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTargetDialog,
            tooltip: AppLocalizations.of(context)!.setTarget,
          ),
        ],
      ),
      body: Column(
        children: [
          // Top section: Stats or modes
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.target,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$_target',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.voiceMode,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Switch(
                      value: _isVoiceEnabled,
                      onChanged: _toggleVoiceMode,
                      activeThumbColor: AppColors.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_target == 100)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: List.generate(_tasbihPhases.length, (index) {
                  final phase = _tasbihPhases[index];
                  final isActive = _phaseIndex == index;
                  final isDone = _phaseIndex > index || _count >= 100;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.cardSurface.withValues(alpha: 0.8)
                          : AppColors.background,
                      border: Border.all(
                        color: isActive ? AppColors.accent : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.accent
                                : (isDone
                                    ? AppColors.success
                                    : AppColors.cardSurface),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${phase['count']}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isActive
                                          ? AppColors.background
                                          : AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (phase['arabic'].toString().isNotEmpty)
                                Text(
                                  phase['arabic'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              if (phase['translit'].toString().isNotEmpty)
                                Text(
                                  phase['translit'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: index == 3 ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? AppColors.accent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              if (phase['translation'].toString().isNotEmpty)
                                Text(
                                  phase['translation'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

          Expanded(
            child: GestureDetector(
              onTap: _incrementCount,
              behavior: HitTestBehavior.opaque, // Catch taps anywhere
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circular progress
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: AppColors.cardSurface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),

                  // Central Counter
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_count',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_isVoiceEnabled)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isListening ? _pulseAnimation.value : 1.0,
                              child: Text(
                                _isListening
                                    ? AppLocalizations.of(context)!.listening
                                    : 'Paused',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _isListening
                                      ? Colors.redAccent
                                      : AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100), // Space for bottom nav
        ],
      ),
    );
  }
}
