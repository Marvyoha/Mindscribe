import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/journal_entry.dart';

/// Compact list tile for a single journal entry.
///
/// Shows the date, mood emoji, optional AI sentiment badge, title, and a
/// preview of either the AI summary or the raw content.
class JournalCard extends StatelessWidget {
  const JournalCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final surface = Theme.of(context).colorScheme.surface;

    final dateLabel = _formatDate(entry.date);
    final emoji = MoodPresets.emojiFor(entry.mood);
    final preview = (entry.aiSummary?.isNotEmpty == true)
        ? entry.aiSummary!
        : entry.content;

    return Card(
      elevation: 0,
      color: isSelected
          ? accent.withValues(alpha: isDark ? 0.18 : 0.12)
          : surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? accent
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onLongPress: onLongPress,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(emoji, style: const TextStyle(fontSize: 20)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.title.isEmpty ? 'Untitled entry' : entry.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.aiSentiment != null) ...[
              const SizedBox(width: 8),
              _SentimentBadge(sentiment: entry.aiSentiment!, accent: accent),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dateLabel,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              preview,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.chevron_right,
          color: isSelected
              ? accent
              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(entryDay).inDays;
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Yesterday, $time';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, $time';
  }
}

// class _MoodAvatar extends StatelessWidget {
//   const _MoodAvatar({required this.mood});
//   final String mood;

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final emoji = MoodPresets.emojiFor(mood);
//     final label = mood.split(' ').skip(1).join(' ');
//     return Container(
//       width: 44,
//       height: 44,
//       decoration: BoxDecoration(
//         color: (Theme.of(context).colorScheme.secondary)
//             .withValues(alpha: 0.14),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(emoji, style: const TextStyle(fontSize: 20)),
//           const SizedBox(height: 1),
//           Text(
//             label.isEmpty ? 'Mood' : label,
//             style: GoogleFonts.spaceGrotesk(
//               fontSize: 9,
//               fontWeight: FontWeight.w600,
//               color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
// }

class _SentimentBadge extends StatelessWidget {
  const _SentimentBadge({required this.sentiment, required this.accent});
  final String sentiment;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        sentiment,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}
