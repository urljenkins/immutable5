import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/glass_container.dart';
import '../models/hadith.dart';

class HadithCard extends StatelessWidget {
  const HadithCard({
    super.key,
    required this.hadith,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  final Hadith hadith;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with narrator and favorite
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hadith.narrator ?? 'Narrator Unknown',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.background,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: isFavorite
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: onFavoriteToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Source / Reference
            Text(
              '${hadith.collection} ${hadith.hadithNumber}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Arabic Text
            Text(
              hadith.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'Amiri', // Assuming Amiri is available
                height: 2.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Transliteration
            if (hadith.transliteration.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hadith.transliteration,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Translation
            Text(
              hadith.translationEn,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),

            // Copy Button & Grading
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Grade chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getGradeColor(hadith.grade).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getGradeColor(hadith.grade)),
                  ),
                  child: Text(
                    hadith.grade,
                    style: GoogleFonts.plusJakartaSans(
                      color: _getGradeColor(hadith.grade),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                // Copy
                TextButton.icon(
                  icon: const Icon(
                    Icons.copy,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  label: Text(
                    'Copy',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            '${hadith.arabic}\n\n${hadith.translationEn}\n\n[${hadith.collection} ${hadith.hadithNumber}]',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hadith copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.toLowerCase().contains('sahih')) return AppColors.accent;
    if (grade.toLowerCase().contains('hasan')) return Colors.orange;
    if (grade.toLowerCase().contains('daif')) return Colors.redAccent;
    return AppColors.textSecondary;
  }
}
