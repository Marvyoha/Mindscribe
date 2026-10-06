import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/models/journal_entry.dart';
import '../core/providers/journal_provider.dart';
import '../widgets/ai_reflection_card.dart';
import 'new_edit_entry_screen.dart';

class EntryDetailScreen extends ConsumerStatefulWidget {
  final JournalEntry entry;
  const EntryDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Watch the provider to reflect updates (like AI analysis results).
    final currentEntry = ref
        .watch(journalProvider)
        .entries
        .firstWhere((e) => e.id == widget.entry.id, orElse: () => widget.entry);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final text = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(currentEntry.date);
    final timeStr = DateFormat('h:mm a').format(currentEntry.date);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NewEditEntryScreen(entry: currentEntry),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit entry',
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete entry',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _regenerateAnalysis(context, ref),
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate analysis',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              Row(
                children: [
                  Text(
                    MoodPresets.emojiFor(currentEntry.mood),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: text,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                currentEntry.title.isEmpty ? 'Untitled' : currentEntry.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: text,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentEntry.content,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  height: 1.7,
                  color: text.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 40),
              AiReflectionCard(
                entry: currentEntry,
                onRegenerate: () => _regenerateAnalysis(context, ref),
              ),
              const SizedBox(height: 48),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitDancingSquare(color: accent, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Regenerating your entry...',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Entry?',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.spaceGrotesk(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (widget.entry.id != null) {
                try {
                  await ref
                      .read(journalProvider.notifier)
                      .deleteEntry(widget.entry.id!);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              }
              if (context.mounted) {
                Navigator.of(context).pop(); // pop dialog
                Navigator.of(context).pop(); // pop detail
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateAnalysis(BuildContext context, WidgetRef ref) async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(journalProvider.notifier)
          .analyzeExistingEntry(widget.entry);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis regenerated successfully')),
        );
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }
}
