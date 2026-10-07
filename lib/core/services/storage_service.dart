import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure, persistent key-value store used for user secrets and app state.
///
/// API keys are kept in [FlutterSecureStorage] (platform keychain/keystore).
/// A default key may also be shipped via `.env` and is consulted as a fallback.
class StorageService {
  StorageService._internal();

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  static const _storage = FlutterSecureStorage();

  static const _keyApiKey = 'openai_api_key';
  static const _keyOnboarding = 'has_completed_onboarding';
  static const _keyApiUrl = 'openai_api_url';
  static const _keyThemeMode = 'theme_mode';

  // --- API key -----------------------------------------------------------

  /// Reads the user-supplied API key from secure storage.
  Future<String?> getApiKey() => _storage.read(key: _keyApiKey);

  /// Persists the user-supplied API key. Pass `null` to delete it.
  Future<void> saveApiKey(String? value) {
    if (value == null || value.isEmpty) {
      return _storage.delete(key: _keyApiKey);
    }
    return _storage.write(key: _keyApiKey, value: value);
  }

  /// The default API key shipped in `.env`, if any.
  String? get defaultApiKey => dotenv.env['OPENAI_API_KEY'];

  /// The active API key: secure-storage value first, then the dotenv default.
  Future<String?> resolveApiKey() async {
    final stored = await getApiKey();
    if (stored != null && stored.isNotEmpty) return stored;
    return defaultApiKey;
  }

  // --- API base URL ------------------------------------------------------

  Future<String?> getApiUrl() => _storage.read(key: _keyApiUrl);

  Future<void> saveApiUrl(String? value) {
    if (value == null || value.isEmpty) {
      return _storage.delete(key: _keyApiUrl);
    }
    return _storage.write(key: _keyApiUrl, value: value);
  }

  /// The default base URL shipped in `.env`, if any.
  String? get defaultApiUrl => dotenv.env['OPENAI_BASE_URL'];

  /// The active base URL: secure-storage value first, then the dotenv default.
  Future<String?> resolveApiUrl() async {
    final stored = await getApiUrl();
    if (stored != null && stored.isNotEmpty) return stored;
    return defaultApiUrl;
  }

  // --- Onboarding --------------------------------------------------------

  Future<bool> hasCompletedOnboarding() async {
    final value = await _storage.read(key: _keyOnboarding);
    return value == 'true';
  }

  Future<void> setCompletedOnboarding(bool value) =>
      _storage.write(key: _keyOnboarding, value: value.toString());

  // --- Theme mode --------------------------------------------------------
  Future<String?> getThemeMode() => _storage.read(key: _keyThemeMode);
  Future<void> saveThemeMode(String? value) {
    if (value == null || value.isEmpty) {
      return _storage.delete(key: _keyThemeMode);
    }
    return _storage.write(key: _keyThemeMode, value: value);
  }

  // --- Data reset --------------------------------------------------------

  /// Wipes all locally stored user data (secure storage only).
  Future<void> clearAllData() => _storage.deleteAll();
}