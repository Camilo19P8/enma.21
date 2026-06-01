## 🚀 Características Avanzadas del Chatbot ENMA

Estos son mejoras opcionales que puedes implementar para mejorar la funcionalidad del chatbot.

---

### 1. 💾 Guardar Historial de Conversaciones

**Descripción:** Persiste el historial en Firebase para recuperarlo posteriormente.

**Archivo:** `lib/services/chat_history_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveChatMessage({
    required String message,
    required bool isUserMessage,
    required DateTime timestamp,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .add({
            'message': message,
            'isUserMessage': isUserMessage,
            'timestamp': timestamp.toIso8601String(),
          });
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory({
    int limit = 50,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data())
          .toList()
          .reversed
          .toList();
    } catch (e) {
      print('Error getting chat history: $e');
      return [];
    }
  }

  Future<void> clearChatHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history');

      final docs = await collection.get();
      for (var doc in docs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }
}
```

**Usar en el chatbot:**

```dart
class _ChatbotFloatingWidgetState extends State<ChatbotFloatingWidget> {
  late ChatHistoryService _historyService;

  @override
  void initState() {
    super.initState();
    _historyService = ChatHistoryService();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final history = await _historyService.getChatHistory();
    // Cargar mensajes anteriores
  }

  Future<void> _sendMessage() async {
    // ... código existente ...

    // Guardar en historial
    await _historyService.saveChatMessage(
      message: message,
      isUserMessage: true,
      timestamp: DateTime.now(),
    );
  }
}
```

---

### 2. 🎤 Entrada de Voz

**Descripción:** Permite al usuario hablar en lugar de escribir.

**Dependencia a agregar en pubspec.yaml:**

```yaml
speech_to_text: ^6.1.0
```

**Archivo:** `lib/widgets/voice_input_button.dart`

```dart
import 'package:speech_to_text/speech_to_text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(String) onSpeechRecognized;

  const VoiceInputButton({
    Key? key,
    required this.onSpeechRecognized,
  }) : super(key: key);

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  late SpeechToText _speechToText;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(
        onError: (error) => print('Error: $error'),
        onStatus: (status) => print('Status: $status'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              widget.onSpeechRecognized(result.recognizedWords);
              setState(() => _isListening = false);
            }
          },
          localeId: 'es_ES',
        );
      }
    } else {
      _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _startListening,
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _isListening ? Colors.red : AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          FontAwesomeIcons.microphone,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
```

---

### 3. 🎙️ Respuesta de Voz

**Descripción:** El chatbot puede leer sus respuestas en voz alta.

**Dependencia:**

```yaml
flutter_tts: ^3.8.0
```

**Archivo:** `lib/services/text_to_speech_service.dart`

```dart
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  late FlutterTts _flutterTts;

  TextToSpeechService() {
    _initializeTTS();
  }

  void _initializeTTS() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("es-ES");
    _flutterTts.setSpeechRate(0.5);
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> pause() async {
    await _flutterTts.pause();
  }
}
```

---

### 4. 📊 Análisis de Sentimientos

**Descripción:** Analiza el sentimiento del usuario para personalizar respuestas.

**Dependencia:**

```yaml
sentiment_dart: ^0.0.9
```

**Archivo:** `lib/services/sentiment_analysis_service.dart`

```dart
class SentimentAnalysisService {
  // Palabras positivas comunes
  static const _positiveWords = [
    'bien', 'genial', 'excelente', 'perfecto', 'gracias',
    'me encanta', 'fantástico', 'asombroso'
  ];

  // Palabras negativas comunes
  static const _negativeWords = [
    'malo', 'horrible', 'terrible', 'odio', 'problema',
    'error', 'falla', 'no funciona'
  ];

  SentimentType analyzeSentiment(String text) {
    final lowercaseText = text.toLowerCase();

    final positiveCount = _positiveWords
        .where((word) => lowercaseText.contains(word))
        .length;

    final negativeCount = _negativeWords
        .where((word) => lowercaseText.contains(word))
        .length;

    if (positiveCount > negativeCount) {
      return SentimentType.positive;
    } else if (negativeCount > positiveCount) {
      return SentimentType.negative;
    }
    return SentimentType.neutral;
  }
}

enum SentimentType {
  positive,
  negative,
  neutral,
}
```

---

### 5. 🔄 Actualizaciones en Tiempo Real

**Descripción:** Recibe actualizaciones de datos meteorológicos en tiempo real.

```dart
class RealtimeWeatherService {
  late StreamSubscription<DocumentSnapshot> _subscription;

  Stream<Map<String, dynamic>> getWeatherStream() {
    return FirebaseFirestore.instance
        .collection('weather_data')
        .doc('latest')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return {
              'temperature': snapshot['temperature'] ?? 0.0,
              'humidity': snapshot['humidity'] ?? 0.0,
              'pressure': snapshot['pressure'] ?? 0.0,
              'windSpeed': snapshot['windSpeed'] ?? 0.0,
              'windDirection': snapshot['windDirection'] ?? 0.0,
              'precipitation': snapshot['precipitation'] ?? 0.0,
            };
          }
          return {};
        });
  }

  void dispose() {
    _subscription.cancel();
  }
}
```

---

### 6. 📱 Notificaciones Push

**Descripción:** Envía notificaciones cuando hay cambios importantes.

**Dependencia:**

```yaml
firebase_messaging: ^14.6.0
```

**Archivo:** `lib/services/notification_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      });
    }
  }

  static Future<void> sendNotification({
    required String title,
    required String body,
  }) async {
    // Implementar envío de notificación
  }
}
```

---

### 7. 🎨 Temas Personalizados

**Descripción:** Permite al usuario cambiar el tema del chatbot.

```dart
enum ChatbotTheme {
  dark,
  light,
  ocean,
  forest,
  sunset,
}

class ChatbotThemeManager {
  static Color getBackgroundColor(ChatbotTheme theme) {
    switch (theme) {
      case ChatbotTheme.dark:
        return AppColors.darkBgSecondary;
      case ChatbotTheme.light:
        return Colors.grey[100]!;
      case ChatbotTheme.ocean:
        return Color(0xFF0077B6);
      case ChatbotTheme.forest:
        return Color(0xFF2D6A4F);
      case ChatbotTheme.sunset:
        return Color(0xFFFF6B6B);
    }
  }

  static Color getPrimaryColor(ChatbotTheme theme) {
    switch (theme) {
      case ChatbotTheme.dark:
        return AppColors.primary;
      case ChatbotTheme.light:
        return Colors.blue;
      case ChatbotTheme.ocean:
        return Color(0xFF00D4FF);
      case ChatbotTheme.forest:
        return Color(0xFF52B788);
      case ChatbotTheme.sunset:
        return Color(0xFFFFD60A);
    }
  }
}
```

---

### 8. 🔗 Integración con Acciones

**Descripción:** El chatbot puede ejecutar acciones (abrir pantallas, etc.).

```dart
class ChatbotActionHandler {
  static void handleAction(
    BuildContext context,
    String action,
    Map<String, dynamic> params,
  ) {
    switch (action) {
      case 'open_screen':
        _openScreen(context, params['screen']);
        break;
      case 'call_function':
        _callFunction(params['function']);
        break;
      case 'navigate':
        _navigate(context, params['route']);
        break;
    }
  }

  static void _openScreen(BuildContext context, String screen) {
    // Navegar a la pantalla especificada
  }

  static void _callFunction(String function) {
    // Ejecutar función específica
  }

  static void _navigate(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }
}
```

---

### 9. 📈 Estadísticas de Uso

**Descripción:** Rastrear uso del chatbot para análisis.

```dart
class ChatbotAnalyticsService {
  Future<void> logUserQuery(String query) async {
    try {
      await FirebaseFirestore.instance
          .collection('analytics')
          .collection('queries')
          .add({
            'query': query,
            'timestamp': DateTime.now(),
            'userId': FirebaseAuth.instance.currentUser?.uid,
          });
    } catch (e) {
      print('Error logging query: $e');
    }
  }

  Future<Map<String, dynamic>> getUsageStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('analytics')
          .collection('queries')
          .count()
          .get();

      return {
        'total_queries': snapshot.count,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      return {};
    }
  }
}
```

---

### 10. 🧠 Aprendizaje Continuo

**Descripción:** El chatbot mejora con el tiempo basado en retroalimentación.

```dart
class FeedbackService {
  Future<void> submitFeedback({
    required String message,
    required String response,
    required bool helpful,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .add({
            'message': message,
            'response': response,
            'helpful': helpful,
            'timestamp': DateTime.now(),
            'userId': FirebaseAuth.instance.currentUser?.uid,
          });
    } catch (e) {
      print('Error submitting feedback: $e');
    }
  }
}
```

---

### 📋 Implementación Gradual

**Fase 1 (Actual):** Chatbot básico funcional ✅

**Fase 2:** Agregar:

- Historial de conversaciones
- Entrada de voz

**Fase 3:** Agregar:

- Respuesta de voz
- Análisis de sentimientos

**Fase 4:** Agregar:

- Actualizaciones en tiempo real
- Notificaciones push

**Fase 5:** Agregar:

- Temas personalizados
- Acciones integradas

---

### 🎯 Prioridades Recomendadas

1. **Alta:** Historial persistente (más útil)
2. **Alta:** Entrada de voz (mejor UX)
3. **Media:** Respuesta de voz (accesibilidad)
4. **Media:** Estadísticas (análisis)
5. **Baja:** Temas personalizados (estética)

---

**Última actualización:** 14 de mayo de 2026  
**Versión:** 1.0.0
