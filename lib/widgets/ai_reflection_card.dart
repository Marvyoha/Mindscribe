import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/journal_entry.dart';

/// Styled callout box presenting an entry's AI reflection results.
///
/// Shows the 2-sentence summary, a sentiment badge, the bulleted takeaways,
/// and the personalized reflection prompt. Empty fields are omitted so the
/// card degrades gracefully for un-analyzed entries.
class AiReflectionCard extends StatelessWidget {
  const AiReflectionCard({super.key, required this.entry, this.onRegenerate});

  final JournalEntry entry;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final surface = Theme.of(context).colorScheme.surface;
    final bodyColor = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF334155);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final hasContent =
        entry.aiSummary != null ||
        entry.aiSentiment != null ||
        (entry.aiTakeaways != null && entry.aiTakeaways!.isNotEmpty) ||
        entry.aiReflectionPrompt != null;

    if (!hasContent) {
      return _EmptyState(isDark: isDark, muted: muted);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Reflection',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              if (onRegenerate != null)
                IconButton(
                  onPressed: onRegenerate,
                  icon: Icon(Icons.refresh, color: muted, size: 20),
                  tooltip: 'Regenerate reflection',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (entry.aiSentiment != null) ...[
            const SizedBox(height: 14),
            _SentimentPill(sentiment: entry.aiSentiment!, accent: accent),
          ],
          if (entry.aiSummary != null) ...[
            const SizedBox(height: 16),
            Text(
              entry.aiSummary!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                height: 1.5,
                color: bodyColor,
              ),
            ),
          ],
          if (entry.aiTakeaways != null && entry.aiTakeaways!.isNotEmpty) ...[
            const SizedBox(height: 18),
            ...entry.aiTakeaways!.map(
              (takeaway) => _TakeawayRow(
                takeaway: takeaway,
                bodyColor: bodyColor,
                muted: muted,
              ),
            ),
          ],
          if (entry.aiReflectionPrompt != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_bubble_outline, color: accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.aiReflectionPrompt!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: bodyColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SentimentPill extends StatelessWidget {
  const _SentimentPill({required this.sentiment, required this.accent});
  final String sentiment;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        sentiment,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _TakeawayRow extends StatelessWidget {
  const _TakeawayRow({
    required this.takeaway,
    required this.bodyColor,
    required this.muted,
  });

  final String takeaway;
  final Color bodyColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.bolt, color: muted, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              takeaway,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13.5,
                height: 1.45,
                color: bodyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark, required this.muted});
  final bool isDark;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_outlined, color: muted, size: 28),
          const SizedBox(height: 10),
          Text(
            'No AI reflection yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Analyze with AI & Save" to generate a summary, takeaways, and a reflection prompt.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              color: muted,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
