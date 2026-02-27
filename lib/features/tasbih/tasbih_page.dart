import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../shared/app_colors.dart';
import '../../generated/app_localizations.dart';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> with SingleTickerProviderStateMixin {
  int _count = 0;
  int _target = 33;
  bool _isVoiceEnabled = false;
  bool _isListening = false;
  late stt.SpeechToText _speech;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() => _isListening = status == 'listening');
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error: ${errorNotification.errorMsg}')),
            );
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
    _speech.listen(
      onResult: (result) {
        // Simple logic: if we detect a pause or a new segment, we count
        // For better accuracy, we might analyze the words, but for a simple counter,
        // detecting speech segments is a start.
        // However, standard STT returns a stream of text.
        // A simple approach for "counting" via voice is harder without specific keywords.
        // Let's assume ANY significant speech input counts as 1 for now,
        // or we look for specific words if needed.
        // A better approach for "Tasbih" might be to just listen for *any* utterance.

        // This is a naive implementation where any result updates count.
        // To prevent rapid firing, we might need a debounce or only count on 'final' results.
        if (result.finalResult) {
             _incrementCount();
             // Restart listening for the next phrase
             if (_isVoiceEnabled && mounted) {
               Future.delayed(const Duration(milliseconds: 100), () {
                 if (mounted && _isVoiceEnabled) _startListening();
               });
             }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      partialResults: false,
    );
  }

  void _showTargetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text(AppLocalizations.of(context)!.setTarget, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('33', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                setState(() => _target = 33);
                Navigator.pop(context);
              },
            ),
             ListTile(
              title: const Text('100', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                setState(() => _target = 100);
                Navigator.pop(context);
              },
            ),
             ListTile(
              title: const Text('Infinite (Custom)', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                 // Simple custom input could be added here
                 setState(() => _target = 99999);
                 Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_count / _target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tasbih, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
                     Text(AppLocalizations.of(context)!.target, style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
                     Text('$_target', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                Row(
                  children: [
                    Text(AppLocalizations.of(context)!.voiceMode, style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
                    Switch(
                      value: _isVoiceEnabled,
                      onChanged: _toggleVoiceMode,
                      activeColor: AppColors.accent,
                    ),
                  ],
                )
              ],
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
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: AppColors.cardSurface,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
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
                                _isListening ? AppLocalizations.of(context)!.listening : 'Paused',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _isListening ? Colors.redAccent : AppColors.textSecondary,
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
