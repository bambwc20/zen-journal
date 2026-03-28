import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/core/network/api_client.dart';

part 'ai_api_client.g.dart';

/// Response model for AI reflection API.
class AiReflectionResponse {
  final String emotionAnalysis;
  final String patternInsight;
  final String actionSuggestion;

  const AiReflectionResponse({
    required this.emotionAnalysis,
    required this.patternInsight,
    required this.actionSuggestion,
  });

  factory AiReflectionResponse.fromJson(Map<String, dynamic> json) {
    return AiReflectionResponse(
      emotionAnalysis: json['emotion_analysis'] as String? ?? '',
      patternInsight: json['pattern_insight'] as String? ?? '',
      actionSuggestion: json['action_suggestion'] as String? ?? '',
    );
  }
}

/// Response model for weekly AI report API.
class WeeklyReportResponse {
  final String summary;
  final String moodTrend;
  final List<String> keyInsights;

  const WeeklyReportResponse({
    required this.summary,
    required this.moodTrend,
    required this.keyInsights,
  });

  factory WeeklyReportResponse.fromJson(Map<String, dynamic> json) {
    return WeeklyReportResponse(
      summary: json['summary'] as String? ?? '',
      moodTrend: json['mood_trend'] as String? ?? '',
      keyInsights: (json['key_insights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// AI API client that proxies requests to Claude Haiku via a Cloudflare Workers proxy.
/// Uses [ApiClient] from core/network for HTTP communication.
///
/// The proxy server handles:
/// - Claude API key management (never exposed to client)
/// - Rate limiting
/// - Request/response transformation
///
/// Endpoints:
/// - POST /api/reflect — Generate AI reflection for a single entry
/// - POST /api/weekly-report — Generate weekly AI report (premium)
class AiApiClient {
  final ApiClient _apiClient;

  AiApiClient(this._apiClient);

  /// Calls the AI proxy to generate a reflection for a journal entry.
  /// Sends the current entry text plus up to 7 days of context entries.
  ///
  /// The proxy server constructs the Claude API prompt with:
  /// - System prompt defining the reflection format
  /// - Context window of recent entries
  /// - Current entry content
  /// - Mood level for emotional context
  Future<AiReflectionResponse> getReflection({
    required String currentEntry,
    required List<String> contextEntries,
    required int moodLevel,
  }) async {
    final response = await _apiClient.post(
      '/api/reflect',
      body: {
        'current_entry': currentEntry,
        'context_entries': contextEntries,
        'mood_level': moodLevel,
      },
    );

    return AiReflectionResponse.fromJson(response);
  }

  /// Calls the AI proxy to generate a weekly report (premium feature).
  /// Sends all entries for the week along with their mood levels.
  Future<WeeklyReportResponse> getWeeklyReport({
    required List<String> entries,
    required List<int> moodLevels,
  }) async {
    final response = await _apiClient.post(
      '/api/weekly-report',
      body: {
        'entries': entries,
        'mood_levels': moodLevels,
      },
    );

    return WeeklyReportResponse.fromJson(response);
  }

  // TODO: v1.2 — AI semantic search endpoint
  // Future<List<int>> semanticSearch(String query) async { ... }

  // TODO: v1.2 — AI custom prompt generation (premium)
  // Future<String> generateCustomPrompt(List<String> recentEntries) async { ... }
}

@riverpod
AiApiClient aiApiClient(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AiApiClient(apiClient);
}
