import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/journal_entry.dart';
import '../core/providers/journal_provider.dart';
import '../widgets/mood_selector.dart';
import 'entry_detail_screen.dart';

/// Form for creating a new journal entry or editing an existing one.
///
/// Features auto-save fallback (local save without AI if offline/unconfigured)
/// and an explicit "Analyze with AI & Save" flow with a loading spinner.
class NewEditEntryScreen extends ConsumerStatefulWidget {
  const NewEditEntryScreen({super.key, this.entry});

  final JournalEntry? entry;

  @override
  ConsumerState<NewEditEntryScreen> createState() => _NewEditEntryScreenState();
}

class _NewEditEntryScreenState extends ConsumerState<NewEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _selectedMood;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleController = TextEditingController(text: e?.title ?? '');
    _contentController = TextEditingController(text: e?.content ?? '');
    _selectedMood = e?.mood.isNotEmpty == true
        ? e!.mood
        : MoodPresets.moods.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.entry != null;

  Future<void> _save({required bool analyzeWithAi}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    final now = DateTime.now();
    final base =
        widget.entry ??
        JournalEntry(
          title: title,
          content: content,
          date: now,
          mood: _selectedMood,
        );

    final entryToSave = base.copyWith(
      title: title,
      content: content,
      mood: _selectedMood,
    );

    final notifier = ref.read(journalProvider.notifier);

    try {
      int? savedId;
      if (_isEditing) {
        await notifier.updateEntry(entryToSave, analyzeWithAi: analyzeWithAi);
      } else {
        savedId = await notifier.saveEntry(entryToSave, analyzeWithAi: analyzeWithAi);
      }
      if (mounted) {
        setState(() => _isSaving = false);
        if (!_isEditing && analyzeWithAi == true) {
          final savedEntry = savedId != null
              ? ref.read(journalProvider).entries.firstWhere((e) => e.id == savedId, orElse: () => entryToSave)
              : entryToSave;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EntryDetailScreen(entry: savedEntry),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final surface = Theme.of(context).colorScheme.surface;
    final textColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF1E293B);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Entry' : 'New Entry',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(analyzeWithAi: false),
            child: Text(
              'Save',
              style: GoogleFonts.spaceGrotesk(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                MoodSelector(
                  selectedMood: _selectedMood,
                  onMoodSelected: (mood) =>
                      setState(() => _selectedMood = mood),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Title (optional)',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      color: muted,
                    ),
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  maxLines: 12,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please write something.'
                      : null,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    height: 1.6,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind today? Write freely...',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      color: muted,
                    ),
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => _save(analyzeWithAi: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                    label: Text(
                      'Analyze with AI & Save',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isSaving)
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
                          _isEditing
                              ? 'Updating your entry...'
                              : 'Reflecting on your words...',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
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
}
