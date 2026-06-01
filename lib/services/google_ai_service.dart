import 'package:google_generative_ai/google_generative_ai.dart';

enum _ReplyLanguage { spanish, english }

class GoogleAIService {
  static const String _fallbackApiKey = '';
  static const String _configuredApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static String get _apiKey {
    if (_runtimeApiKey != null && _runtimeApiKey!.trim().isNotEmpty) {
      return _runtimeApiKey!.trim();
    }
    if (_configuredApiKey.trim().isNotEmpty) {
      return _configuredApiKey.trim();
    }
    return _fallbackApiKey;
  }

  static String? _runtimeApiKey;

  /// Establece una API key en tiempo de ejecución (útil para pruebas).
  void setRuntimeApiKey(String key) {
    _runtimeApiKey = key;
    _initializeModel(0);
  }

  static const List<String> _modelCandidates = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash-8b',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
    'gemini-1.5-pro-latest',
    'gemini-1.5-pro',
  ];

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

  static String _buildPrompt({
    required String message,
    required _ReplyLanguage language,
    Map<String, dynamic>? weatherData,
  }) {
    final languageInstruction = language == _ReplyLanguage.english
        ? 'Reply in English because the user asked in English.'
        : 'Responde en español porque el usuario preguntó en español.';

    final weatherBlock = weatherData == null || weatherData.isEmpty
        ? ''
        : '''
Datos meteorológicos actuales:
- Temperature: ${weatherData['temperature'] ?? 'N/A'}
- Humidity: ${weatherData['humidity'] ?? 'N/A'}
- Pressure: ${weatherData['pressure'] ?? 'N/A'}
- Wind speed: ${weatherData['windSpeed'] ?? 'N/A'}
- Wind direction: ${weatherData['windDirection'] ?? 'N/A'}
- Precipitation: ${weatherData['precipitation'] ?? 'N/A'}
''';

    return '''
You are ENMA, a helpful assistant for a meteorological app and general support.
$languageInstruction
Keep the answer concise, useful, and friendly.
If the question is about transgender people, answer respectfully and factually. Use inclusive language, avoid stereotypes, and if asked about health, legal, or safety issues, give general information and suggest a qualified professional when needed.
Do not use preconfigured local answers. Rely only on the live conversation and the provided context.
If you do not know something, say so clearly.
${weatherBlock.isEmpty ? '' : weatherBlock}

User message:
$message
''';
  }

  late final GenerativeModel _model;
  late ChatSession _chatSession;
  int _currentModelIndex = 0;

  GoogleAIService() {
    _initializeModel();
  }

  void _initializeModel([int modelIndex = 0]) {
    _currentModelIndex = modelIndex;
    _model = GenerativeModel(
      model: _modelCandidates[_currentModelIndex],
      apiKey: _apiKey,
    );
    _chatSession = _model.startChat();
  }

  bool _isModelUnavailableError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('is not found for api version') ||
        msg.contains('not supported for generatecontent') ||
        msg.contains('models/') && msg.contains('not found');
  }

  bool _isQuotaExceededError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('quota') ||
        msg.contains('exceeded') ||
        msg.contains('quotaexceeded') ||
        msg.contains('rate_limit') ||
        msg.contains('rate limit') ||
        msg.contains('resource_exhausted');
  }

  Future<T> _runWithModelFallback<T>(Future<T> Function() operation) async {
    Object? lastError;

    for (int i = _currentModelIndex; i < _modelCandidates.length; i++) {
      if (i != _currentModelIndex) {
        _initializeModel(i);
      }

      try {
        return await operation();
      } catch (e) {
        lastError = e;
        if (_isQuotaExceededError(e)) {
          throw Exception('QuotaExceeded: ${e.toString()}');
        }
        if (!_isModelUnavailableError(e)) {
          rethrow;
        }
      }
    }

    throw lastError ??
        Exception('No hay modelos disponibles para esta API key.');
  }

  Future<String> sendMessage(String message) async {
    final language = _detectLanguage(message);

    if (_apiKey.isEmpty) {
      return _getConfigurationErrorMessage(language);
    }

    try {
      final response = await _runWithModelFallback(
        () => _chatSession.sendMessage(
          Content.text(
            _buildPrompt(
              message: message,
              language: language,
            ),
          ),
        ),
      );

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      }
      return 'No se pudo obtener una respuesta.';
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('quota') ||
          err.contains('exceeded') ||
          err.contains('quotaexceeded') ||
          err.contains('quotaexceeded:') ||
          err.contains('resource_exhausted')) {
        return _getQuotaExceededMessage(language);
      }
      return _getErrorMessage(language, e.toString());
    }
  }

  Future<String> getContextualResponse(
    String userQuestion,
    Map<String, dynamic> weatherData,
  ) async {
    final language = _detectLanguage(userQuestion);

    if (_apiKey.isEmpty) {
      return _getConfigurationErrorMessage(language);
    }

    try {
      final response = await _runWithModelFallback(
        () => _model.generateContent([
          Content.text(
            _buildPrompt(
              message: userQuestion,
              language: language,
              weatherData: weatherData,
            ),
          ),
        ]),
      );

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      }
      return 'No se pudo generar una respuesta.';
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('quota') ||
          err.contains('exceeded') ||
          err.contains('quotaexceeded') ||
          err.contains('quotaexceeded:') ||
          err.contains('resource_exhausted')) {
        return _getQuotaExceededMessage(language);
      }
      return _getErrorMessage(language, e.toString());
    }
  }

  static String _getQuotaExceededMessage(_ReplyLanguage language) {
    if (language == _ReplyLanguage.english) {
      return 'The chatbot is currently busy. Please try again in a moment.';
    }

    return 'El chatbot está ocupado en este momento. Intenta de nuevo en un momento.';
  }

  static String _getErrorMessage(_ReplyLanguage language, String error) {
    return language == _ReplyLanguage.english
        ? 'Error: $error'
        : 'Error: $error';
  }

  static String _getConfigurationErrorMessage(_ReplyLanguage language) {
    if (language == _ReplyLanguage.english) {
      return 'The chatbot is missing a valid Gemini API key. Configure GEMINI_API_KEY with a valid key and restart the app.';
    }

    return 'Falta una clave válida de Gemini para el chatbot. Configura GEMINI_API_KEY con una clave válida y reinicia la app.';
  }

  void resetChat() {
    _chatSession = _model.startChat();
  }
}
