import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/journal_entry.dart';
import '../services/storage_service.dart';
import '../utils/api_client.dart';
import '../utils/logger.dart';

class OpenAIService {
  OpenAIService._internal();

  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;

  static const _defaultModel = 'gpt-4o-mini';
  final ApiClient _api = ApiClient();
  final StorageService _storage = StorageService();
  final _log = logger(OpenAIService);

  Future<JournalEntry> analyzeEntry(JournalEntry entry) async {
    final apiKey = await _storage.resolveApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      _log.w('OpenAI API key is missing');
      throw Exception(
        'OpenAI API key is missing. Please configure it in Settings.',
      );
    }

    final rawUrl =
        await _storage.resolveApiUrl() ?? 'https://api.openai.com/v1';
    final baseUrl = rawUrl
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'/+$'), '');
    final model = dotenv.env['OPENAI_BASE_URL']?.contains('free') == true
        ? dotenv.env['OPENAI_MODEL']
        : _defaultModel;

    final prompt = _buildPrompt(entry);
    final body = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'response_format': {'type': 'json_object'},
    };

    try {
      final response = dotenv.env['OPENAI_BASE_URL']!.contains('free')
          ? await _api.post(
              endpoint: '$baseUrl/chat/completions',
              body: body,
              additionalHeaders: {
                'Authorization': 'Bearer $apiKey',
                'ngrok-skip-browser-warning': 'true',
              },
            )
          : await _api.post(
              endpoint: '$baseUrl/chat/completions',
              body: body,
              additionalHeaders: {'Authorization': 'Bearer $apiKey'},
            );

      final content = _extractContent(response);
      if (content == null) return entry;

      final parsed = _parseJson(content);
      if (parsed == null) return entry;

      return entry.copyWith(
        aiSummary: _str(parsed['summary']),
        aiSentiment: _str(parsed['sentiment']),
        aiTakeaways: _takeaways(parsed['takeaways']),
        aiReflectionPrompt: _str(parsed['reflection_prompt']),
      );
    } on DioException catch (e) {
      _log.e('DioException during AI analysis', error: e);
      rethrow;
    } catch (e) {
      _log.e('Unexpected error during AI analysis', error: e);
      rethrow;
    }
  }

  static const _systemPrompt = '''
You are MindScribe, an empathetic AI reflection companion for a personal journaling app.

Read the user's journal entry and produce a structured JSON response with EXACTLY these four keys:
- "summary": a concise 2-sentence summary of the entry.
- "sentiment": a single-word dominant emotion (e.g. "Grateful", "Anxious", "Reflective", "Optimistic", "Tired").
- "takeaways": an array of exactly 3 short, insightful strings — the key lessons or realizations.
- "reflection_prompt": one deep, empathetic follow-up question to help the user reflect further.

Rules:
- Output ONLY valid JSON. No markdown fences, no commentary, no extra keys.
- Keep each takeaway under 20 words.
- Be warm, non-judgmental, and psychologically safe.
''';

  String _buildPrompt(JournalEntry entry) {
    final buffer = StringBuffer()
      ..writeln('Title: ${entry.title}')
      ..writeln('Mood: ${entry.mood}')
      ..writeln('Date: ${entry.date.toIso8601String()}')
      ..writeln()
      ..writeln('Content:')
      ..write(entry.content);
    return buffer.toString();
  }

  String? _extractContent(dynamic data) {
    if (data is Map) {
      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices[0];
        if (first is Map) {
          final message = first['message'];
          if (message is Map) {
            final content = message['content'];
            if (content is String && content.isNotEmpty) return content;
          }
        }
      }
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        throw FormatException('API error: ${error['message']}');
      }
    }
    return null;
  }

  Map<String, dynamic>? _parseJson(String content) {
    final trimmed = content.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    final slice = trimmed.substring(start, end + 1);
    try {
      final decoded = jsonDecode(slice);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  String? _str(dynamic value) {
    if (value is String) return value.trim();
    return null;
  }

  List<String>? _takeaways(dynamic value) {
    if (value is List) {
      final list = value
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return list.isEmpty ? null : list;
    }
    return null;
  }
}
