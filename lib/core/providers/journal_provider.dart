import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/journal_entry.dart';
import '../services/database_service.dart';
import '../services/open_ai_service.dart';
import '../utils/logger.dart';

class JournalState {
  const JournalState({
    this.entries = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.isSaving = false,
    this.isAnalyzing = false,
    this.error,
  });

  final List<JournalEntry> entries;
  final String searchQuery;
  final bool isLoading;
  final bool isSaving;
  final bool isAnalyzing;
  final String? error;

  List<JournalEntry> get filteredEntries {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return entries
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.content.toLowerCase().contains(q) ||
            (e.aiSentiment?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  JournalState copyWith({
    List<JournalEntry>? entries,
    String? searchQuery,
    bool? isLoading,
    bool? isSaving,
    bool? isAnalyzing,
    Object? error,
  }) =>
      JournalState(
        entries: entries ?? this.entries,
        searchQuery: searchQuery ?? this.searchQuery,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        isAnalyzing: isAnalyzing ?? this.isAnalyzing,
        error: error?.toString(),
      );
}

final journalProvider = NotifierProvider<JournalNotifier, JournalState>(
  JournalNotifier.new,
);

class JournalNotifier extends Notifier<JournalState> {
  final DatabaseService _db = DatabaseService();
  final OpenAIService _ai = OpenAIService();
  final _log = logger(JournalNotifier);

  @override
  JournalState build() => const JournalState();

  Future<void> loadEntries() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final entries = await _db.getAllEntries();
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      _log.e('Failed to load entries: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load entries: $e');
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<int?> saveEntry(JournalEntry entry, {bool analyzeWithAi = false}) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final enriched = analyzeWithAi ? await _analyze(entry) : entry;
      final id = await _db.insertEntry(enriched);
      await loadEntries();
      return id;
    } catch (e) {
      _log.e('Failed to save entry: $e');
      state = state.copyWith(isSaving: false, error: 'Failed to save entry: $e');
      rethrow;
    }
  }

  Future<bool> updateEntry(JournalEntry entry, {bool analyzeWithAi = false}) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final enriched = analyzeWithAi ? await _analyze(entry) : entry;
      await _db.updateEntry(enriched);
      await loadEntries();
      return true;
    } catch (e) {
      _log.e('Failed to update entry: $e');
      state = state.copyWith(isSaving: false, error: 'Failed to update entry: $e');
      rethrow;
    }
  }

  Future<bool> deleteEntry(int id) async {
    try {
      await _db.deleteEntry(id);
      await loadEntries();
      return true;
    } catch (e) {
      _log.e('Failed to delete entry: $e');
      state = state.copyWith(error: 'Failed to delete entry: $e');
      return false;
    }
  }

  Future<JournalEntry?> analyzeExistingEntry(JournalEntry entry) async {
    state = state.copyWith(isAnalyzing: true, error: null);
    try {
      final enriched = await _analyze(entry);
      await _db.updateEntry(enriched);
      await loadEntries();
      return enriched;
    } catch (e) {
      _log.e('Analysis failed: $e');
      state = state.copyWith(isAnalyzing: false, error: 'Analysis failed: $e');
      rethrow;
    }
  }

  Future<JournalEntry> _analyze(JournalEntry entry) async {
    state = state.copyWith(isAnalyzing: true);
    final result = await _ai.analyzeEntry(entry);
    state = state.copyWith(isAnalyzing: false);
    return result;
  }
}