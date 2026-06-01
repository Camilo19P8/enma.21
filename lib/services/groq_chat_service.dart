import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum _ReplyLanguage { spanish, english }

class GroqChatService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _runtimeApiKeyPrefKey = 'groq_runtime_api_key';
  static const String _configuredApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );
  static const String _configuredModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: '',
  );

  static const List<String> _defaultGroqModelCandidates = [
    'llama-3.3-70b-versatile',
    'llama-3.1-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
  ];

  static const List<String> _defaultXaiModelCandidates = [
    'grok-2',
    'grok-beta',
  ];

  static String? _runtimeApiKey;
  static Future<void>? _initialization;

  final List<_ConversationTurn> _history = [];
  int _currentModelIndex = 0;

  GroqChatService() {
    resetChat();
  }

  static Future<void> initialize() async {
    _initialization ??= _loadPersistedConfiguration();
    await _initialization;
  }

  static Future<void> _loadPersistedConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final storedApiKey = prefs.getString(_runtimeApiKeyPrefKey)?.trim() ?? '';
    if (storedApiKey.isNotEmpty) {
      _runtimeApiKey = storedApiKey;
    }
  }

  Future<void> setRuntimeApiKey(String key) async {
    final trimmedKey = key.trim();
    _runtimeApiKey = trimmedKey;

    final prefs = await SharedPreferences.getInstance();
    if (trimmedKey.isEmpty) {
      await prefs.remove(_runtimeApiKeyPrefKey);
    } else {
      await prefs.setString(_runtimeApiKeyPrefKey, trimmedKey);
    }

    resetChat();
  }

  void resetChat() {
    _history.clear();
    _currentModelIndex = 0;
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  static _ReplyLanguage _detectLanguage(String message) {
    final normalized = _normalize(message);
    const spanishSignals = [
      ' que ',
      ' como ',
      ' para ',
      ' por favor',
      ' ayudame',
      ' hola',
      ' gracias',
      ' clima',
      ' temperatura',
      ' humedad',
      ' presion',
      ' viento',
      ' lluvia',
      ' alertas',
      ' historial',
      ' perfil',
      ' dame ',
    ];
    const englishSignals = [
      ' what ',
      ' how ',
      ' please',
      ' help',
      ' weather',
      ' temperature',
      ' humidity',
      ' pressure',
      ' wind',
      ' rain',
      ' history',
      ' alerts',
      ' profile',
      ' tell me ',
    ];

    var spanishScore = 0;
    var englishScore = 0;

    if (message.contains('¿') || message.contains('¡')) {
      spanishScore += 2;
    }

    for (final signal in spanishSignals) {
      if (normalized.contains(signal)) {
        spanishScore++;
      }
    }

    for (final signal in englishSignals) {
      if (normalized.contains(signal)) {
        englishScore++;
      }
    }

    return englishScore > spanishScore
        ? _ReplyLanguage.english
        : _ReplyLanguage.spanish;
  }

  static String _languageInstruction(_ReplyLanguage language) {
    return language == _ReplyLanguage.english
        ? 'Reply in English because the user wrote in English.'
        : 'Responde en español porque el usuario escribió en español.';
  }

  static String _formatWeatherData(Map<String, dynamic>? weatherData) {
    if (weatherData == null || weatherData.isEmpty) {
      return '';
    }

    return '''
Current weather context:
- Temperature: ${weatherData['temperature'] ?? 'N/A'}
- Humidity: ${weatherData['humidity'] ?? 'N/A'}
- Pressure: ${weatherData['pressure'] ?? 'N/A'}
- Wind speed: ${weatherData['windSpeed'] ?? 'N/A'}
- Wind direction: ${weatherData['windDirection'] ?? 'N/A'}
- Precipitation: ${weatherData['precipitation'] ?? 'N/A'}
''';
  }

  String _buildSystemPrompt({
    required _ReplyLanguage language,
    Map<String, dynamic>? weatherData,
  }) {
    final weatherContext = _formatWeatherData(weatherData);

    return '''
You are ENMA, a professional, friendly, natural, precise and helpful conversational assistant for a meteorological app.
${_languageInstruction(language)}
Keep the response in the same language as the user's latest message.
Maintain context across the conversation and use the provided chat history.
Be brief when possible, and detailed only when the user asks for it.
Avoid robotic, repetitive, or overly verbose answers.
If you do not know something, say so clearly.
${weatherContext.isEmpty ? '' : weatherContext}
''';
  }

  String _configuredApiKeyValue() {
    if (_runtimeApiKey != null && _runtimeApiKey!.trim().isNotEmpty) {
      return _runtimeApiKey!.trim();
    }

    final dotenvApiKey = dotenv.env['GROQ_API_KEY']?.trim() ?? '';
    if (dotenvApiKey.isNotEmpty) {
      return dotenvApiKey;
    }

    return _configuredApiKey.trim();
  }

  String _activeBaseUrl() {
    final apiKey = _configuredApiKeyValue();
    if (apiKey.startsWith('xai-')) {
      return 'https://api.x.ai/v1';
    }
    return _baseUrl;
  }

  String _resolveModel(int index) {
    return _modelCandidates[index];
  }

  List<String> get _modelCandidates {
    final apiKey = _configuredApiKeyValue();
    final isXai = apiKey.startsWith('xai-');
    final defaultCandidates = isXai ? _defaultXaiModelCandidates : _defaultGroqModelCandidates;

    var dotenvModel = dotenv.env['GROQ_MODEL']?.trim() ?? '';
    if (dotenvModel == 'grok-beta') {
      dotenvModel = 'grok-2';
    }
    if (dotenvModel.isNotEmpty) {
      final isCompatible = isXai
          ? dotenvModel.toLowerCase().contains('grok')
          : (dotenvModel.toLowerCase().contains('llama') ||
              dotenvModel.toLowerCase().contains('mixtral'));
      if (isCompatible) {
        return [
          dotenvModel,
          ...defaultCandidates.where((model) => model != dotenvModel),
        ];
      }
    }

    var configModel = _configuredModel.trim();
    if (configModel == 'grok-beta') {
      configModel = 'grok-2';
    }
    if (configModel.isNotEmpty) {
      final isCompatible = isXai
          ? configModel.toLowerCase().contains('grok')
          : (configModel.toLowerCase().contains('llama') ||
              configModel.toLowerCase().contains('mixtral'));
      if (isCompatible) {
        return [
          configModel,
          ...defaultCandidates.where(
            (model) => model != configModel,
          ),
        ];
      }
    }

    return defaultCandidates;
  }

  void _trimHistory() {
    const maxTurns = 12;
    const maxMessages = maxTurns * 2;

    if (_history.length <= maxMessages) {
      return;
    }

    _history.removeRange(0, _history.length - maxMessages);
  }

  bool _isUnauthorizedError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('401') ||
        lower.contains('unauthorized') ||
        lower.contains('invalid api key') ||
        lower.contains('api key');
  }

  bool _isQuotaOrRateLimitError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('429') ||
        lower.contains('rate limit') ||
        lower.contains('quota') ||
        lower.contains('too many requests');
  }

  bool _isModelUnavailableError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('404') ||
        lower.contains('model') &&
            (lower.contains('not found') ||
                lower.contains('does not exist'));
  }


  Future<http.Response> _postCompletion({
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    final apiKey = _configuredApiKeyValue();
    if (apiKey.isEmpty) {
      throw StateError('GROQ_API_KEY is not configured.');
    }

    final response = await http.post(
      Uri.parse('${_activeBaseUrl()}/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.4,
        'top_p': 0.9,
        'max_tokens': 700,
        'stream': false,
      }),
    );

    return response;
  }

  Future<String> _requestCompletion({
    required String message,
    required _ReplyLanguage language,
    Map<String, dynamic>? weatherData,
  }) async {
    final apiKey = _configuredApiKeyValue();
    final provider = apiKey.startsWith('xai-') ? 'xAI (Grok)' : 'Groq';
    if (apiKey.isEmpty) {
      return _getConfigurationErrorMessage(language, provider);
    }

    _history.add(_ConversationTurn.user(message));
    _trimHistory();

    final apiMessages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt(
          language: language,
          weatherData: weatherData,
        ),
      },
      ..._history.map(
        (turn) => {
          'role': turn.role,
          'content': turn.content,
        },
      ),
    ];

    Object? lastError;

    for (var index = _currentModelIndex;
        index < _modelCandidates.length;
        index++) {
      final model = _resolveModel(index);

      try {
        final response = await _postCompletion(
          model: model,
          messages: apiMessages,
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          final errorBody = response.body.trim();
          if (_isUnauthorizedError(errorBody) || response.statusCode == 401) {
            return _getConfigurationErrorMessage(language, provider);
          }

          if (_isQuotaOrRateLimitError(errorBody) ||
              response.statusCode == 429) {
            return _getQuotaExceededMessage(language, provider);
          }

          if (_isModelUnavailableError(errorBody) ||
              response.statusCode == 404) {
            lastError = StateError(
              errorBody.isEmpty ? 'Model $model is not available.' : errorBody,
            );
            continue;
          }

          throw StateError(
            errorBody.isEmpty
                ? '$provider request failed with status ${response.statusCode}.'
                : errorBody,
          );
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = decoded['choices'];
        if (choices is List && choices.isNotEmpty) {
          final choice = choices.first;
          if (choice is Map<String, dynamic>) {
            final messageData = choice['message'];
            if (messageData is Map<String, dynamic>) {
              final content = messageData['content'];
              if (content is String && content.trim().isNotEmpty) {
                final normalizedContent = content.trim();
                _history.add(_ConversationTurn.assistant(normalizedContent));
                _trimHistory();
                _currentModelIndex = index;
                return normalizedContent;
              }
            }
          }
        }

        throw StateError('No response content was returned by $provider.');
      } catch (error) {
        lastError = error;
        final errorMessage = error.toString().toLowerCase();
        if (_isQuotaOrRateLimitError(errorMessage)) {
          return _getQuotaExceededMessage(language, provider);
        }

        if (!_isModelUnavailableError(errorMessage)) {
          if (errorMessage.contains('socketexception') ||
              errorMessage.contains('handshakeexception') ||
              errorMessage.contains('timeout')) {
            return _getNetworkErrorMessage(language, provider);
          }

          rethrow;
        }
      }
    }

    throw lastError ?? StateError('No $provider models were available.');
  }

  Future<String> sendMessage(String message) async {
    final language = _detectLanguage(message);

    try {
      return await _requestCompletion(
        message: message,
        language: language,
      );
    } catch (error) {
      return _getErrorMessage(language, error.toString());
    }
  }

  Future<String> getContextualResponse(
    String userQuestion,
    Map<String, dynamic> weatherData,
  ) async {
    final language = _detectLanguage(userQuestion);

    try {
      return await _requestCompletion(
        message: userQuestion,
        language: language,
        weatherData: weatherData,
      );
    } catch (error) {
      return _getErrorMessage(language, error.toString());
    }
  }

  static String _getQuotaExceededMessage(_ReplyLanguage language, String provider) {
    return language == _ReplyLanguage.english
        ? '$provider is currently rate-limited. Please try again in a moment.'
        : '$provider está recibiendo muchas solicitudes. Intenta de nuevo en un momento.';
  }

  static String _getNetworkErrorMessage(_ReplyLanguage language, String provider) {
    return language == _ReplyLanguage.english
        ? 'Network error while contacting $provider. Please check your connection and try again.'
        : 'Se produjo un error de red al conectar con $provider. Revisa tu conexión e intenta de nuevo.';
  }

  static String _getErrorMessage(_ReplyLanguage language, String error) {
    return language == _ReplyLanguage.english
        ? 'Error: $error'
        : 'Error: $error';
  }

  static String _getConfigurationErrorMessage(_ReplyLanguage language, String provider) {
    final configVar = provider == 'Groq' ? 'GROQ_API_KEY' : 'GROQ_API_KEY (xAI)';
    return language == _ReplyLanguage.english
        ? 'The chatbot is missing a valid $provider API key. Configure $configVar with a valid key and restart the app.'
        : 'Falta una clave válida de $provider para el chatbot. Configura $configVar con una clave válida y reinicia la app.';
  }
}

class _ConversationTurn {
  final String role;
  final String content;

  const _ConversationTurn({required this.role, required this.content});

  factory _ConversationTurn.user(String content) {
    return _ConversationTurn(role: 'user', content: content);
  }

  factory _ConversationTurn.assistant(String content) {
    return _ConversationTurn(role: 'assistant', content: content);
  }
}
