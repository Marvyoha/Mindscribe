import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/journal_entry.dart';
import '../core/providers/journal_provider.dart';
import '../core/providers/theme_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/journal_card.dart';
import 'entry_detail_screen.dart';
import 'new_edit_entry_screen.dart';
import 'settings_screen.dart';

/// Main screen: shows the journal feed, real-time search, and a FAB to write.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(journalProvider.notifier).loadEntries());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    ref.read(themeProvider.notifier).toggleTheme();
  }

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _onCardTap(JournalEntry entry) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedIds.contains(entry.id)) {
          _selectedIds.remove(entry.id);
        } else {
          _selectedIds.add(entry.id!);
        }
      });
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)));
  }

  void _onCardLongPress(JournalEntry entry) {
    setState(() {
      _selectedIds.clear();
      _selectedIds.add(entry.id!);
    });
  }

  void _clearSelection() {
    if (_isSelectionMode) {
      setState(() => _selectedIds.clear());
    }
  }

  Future<void> _confirmDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete entr${count == 1 ? 'y' : 'ies'}'),
        content: Text(
          'Delete selected entr${count == 1 ? 'y' : 'ies'}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final id in _selectedIds) {
      await ref.read(journalProvider.notifier).deleteEntry(id);
    }
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final entries = state.filteredEntries;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppHeader(
        onThemeToggle: _toggleTheme,
        onSettings: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _confirmDelete,
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.delete_outline),
              label: Text(
                _selectedIds.length == 1
                    ? 'Delete'
                    : 'Delete (${_selectedIds.length})',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
            )
          : (entries.isEmpty
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NewEditEntryScreen(),
                      ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: Text(
                      'New Entry',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )),
      body: RefreshIndicator(
        onRefresh: () => ref.read(journalProvider.notifier).loadEntries(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) {
                    ref.read(journalProvider.notifier).setSearchQuery(q);
                    if (q.isEmpty) {
                      _clearSelection();
                    }
                  },
                  onTapOutside: (_) {
                    FocusScope.of(context).unfocus();
                    _clearSelection();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by title, content, or emotion...',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: muted,
                    ),

                    prefixIcon: Icon(Icons.search, color: muted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(journalProvider.notifier)
                                  .setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  isDark: isDark,
                  accent: Theme.of(context).colorScheme.secondary,
                  muted: muted,
                  isSearching: _searchController.text.isNotEmpty,
                  onNewEntry: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NewEditEntryScreen(),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: JournalCard(
                        entry: entry,
                        onTap: () => _onCardTap(entry),
                        onLongPress: () => _onCardLongPress(entry),
                        isSelected: _selectedIds.contains(entry.id!),
                      ),
                    );
                  }, childCount: entries.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isDark,
    required this.accent,
    required this.muted,
    required this.isSearching,
    required this.onNewEntry,
  });

  final bool isDark;
  final Color accent;
  final Color muted;
  final bool isSearching;
  final VoidCallback onNewEntry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.menu_book_rounded,
                size: 40,
                color: accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No matching entries' : 'Your journal is empty',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching ? 'Try searching with a different term or emotion.' : 'Start writing your thoughts and let MindScribe reflect on them.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: muted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onNewEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Write first entry',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
