import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/journal_entry.dart';

/// Horizontal row of selectable mood chips.
///
/// Shows the five [MoodPresets] moods with their emoji. The currently
/// selected mood is highlighted with an accent border.
class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  final String selectedMood;
  final ValueChanged<String> onMoodSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: MoodPresets.moods.map((mood) {
            final isSelected = mood == selectedMood;
            final emoji = MoodPresets.emojiFor(mood);
            final label = mood.split(' ').skip(1).join(' ');
            return ChoiceChip(
              selected: isSelected,
              label: Text('$emoji $label'),
              selectedColor: accent.withValues(alpha: 0.18),
              checkmarkColor: accent,
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: isSelected ? BorderSide(color: accent, width: 1.5) : null,
              labelStyle: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: isSelected
                    ? accent
                    : (isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF475569)),
              ),
              shape: const StadiumBorder(),
              onSelected: (_) => onMoodSelected(mood),
            );
          }).toList(),
        ),
      ],
    );
  }
}
