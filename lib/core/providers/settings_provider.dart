import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/database_service.dart';
import '../services/storage_service.dart';

class SettingsState {
  const SettingsState({
    this.apiKey,
    this.apiBaseUrl,
    this.hasCompletedOnboarding = false,
    this.isLoading = true,
  });

  final String? apiKey;
  final String? apiBaseUrl;
  final bool hasCompletedOnboarding;
  final bool isLoading;

  SettingsState copyWith({
    String? apiKey,
    String? apiBaseUrl,
    bool? hasCompletedOnboarding,
    bool? isLoading,
  }) =>
      SettingsState(
        apiKey: apiKey ?? this.apiKey,
        apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
        hasCompletedOnboarding:
            hasCompletedOnboarding ?? this.hasCompletedOnboarding,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Holds the user's API configuration and onboarding status.
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<SettingsState> {
  final StorageService _storage = StorageService();

  @override
  SettingsState build() => const SettingsState();

  /// Loads persisted settings into state. Safe to call multiple times.
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final apiKey = await _storage.resolveApiKey();
    final apiUrl = await _storage.resolveApiUrl();
    final onboarded = await _storage.hasCompletedOnboarding();
    state = state.copyWith(
      apiKey: apiKey,
      apiBaseUrl: apiUrl,
      hasCompletedOnboarding: onboarded,
      isLoading: false,
    );
  }

  Future<void> saveApiKey(String? value) async {
    await _storage.saveApiKey(value);
    state = state.copyWith(apiKey: value);
  }

  Future<void> saveApiUrl(String? value) async {
    await _storage.saveApiUrl(value);
    state = state.copyWith(apiBaseUrl: value);
  }

  Future<void> completeOnboarding() async {
    await _storage.setCompletedOnboarding(true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  Future<void> clearAllData() async {
    await _storage.clearAllData();
    await DatabaseService().clearAllEntries();
    state = const SettingsState();
  }
}