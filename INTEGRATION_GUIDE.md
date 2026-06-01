## 🌡️ Integración del Chatbot con Datos Meteorológicos en Tiempo Real

Este documento explica cómo conectar el chatbot con los datos meteorológicos reales de tu aplicación.

---

### 📊 Estructura de Datos Meteorológicos

El chatbot acepta un mapa con los siguientes datos:

```dart
Map<String, dynamic> weatherData = {
  'temperature': 25.5,           // En °C
  'humidity': 65.0,              // En %
  'pressure': 1013.25,           // En hPa
  'windSpeed': 12.5,             // En km/h
  'windDirection': 45.0,         // En grados (0-360)
  'precipitation': 0.0,          // En mm
};
```

---

### 🔄 Cómo Obtener Datos de tu DataScreen

**Paso 1: Revisa tu DataScreen**

```dart
// lib/screens/data_screen.dart
// Aquí es donde probablemente tengas los datos meteorológicos
```

**Paso 2: Extrae los datos**

Si tu `DataScreen` tiene acceso a Firebase o a una API local, puedes extraer los datos así:

```dart
// Ejemplo: Si usas Firebase Firestore
final weatherDoc = await FirebaseFirestore.instance
    .collection('weather_data')
    .doc('latest')
    .get();

final weatherData = {
  'temperature': weatherDoc['temperature'] ?? 0.0,
  'humidity': weatherDoc['humidity'] ?? 0.0,
  'pressure': weatherDoc['pressure'] ?? 0.0,
  'windSpeed': weatherDoc['windSpeed'] ?? 0.0,
  'windDirection': weatherDoc['windDirection'] ?? 0.0,
  'precipitation': weatherDoc['precipitation'] ?? 0.0,
};
```

**Paso 3: Pasa los datos al chatbot**

Hay varias formas de hacer esto:

---

### 💡 Solución 1: Actualizar MainTabScreen (Recomendado)

#### Modificar `main_tab_screen.dart`:

```dart
// 1. Crear un estado para almacenar datos meteorológicos
class _MainTabScreenState extends State<MainTabScreen> {
  // ... código existente ...

  Map<String, dynamic> _weatherData = {
    'temperature': 'N/A',
    'humidity': 'N/A',
    'pressure': 'N/A',
    'windSpeed': 'N/A',
    'windDirection': 'N/A',
    'precipitation': 'N/A',
  };

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      // Obtener datos de tu fuente (Firebase, API local, etc.)
      final data = await _fetchWeatherData();

      setState(() {
        _weatherData = data;
      });
    } catch (e) {
      print('Error cargando datos meteorológicos: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchWeatherData() async {
    // Implementar según tu fuente de datos
    // Ejemplo con Firebase:
    try {
      final doc = await FirebaseFirestore.instance
          .collection('weather_data')
          .doc('latest')
          .get();

      return {
        'temperature': doc['temperature'] ?? 0.0,
        'humidity': doc['humidity'] ?? 0.0,
        'pressure': doc['pressure'] ?? 0.0,
        'windSpeed': doc['windSpeed'] ?? 0.0,
        'windDirection': doc['windDirection'] ?? 0.0,
        'precipitation': doc['precipitation'] ?? 0.0,
      };
    } catch (e) {
      return {
        'temperature': 'Error',
        'humidity': 'Error',
        'pressure': 'Error',
        'windSpeed': 'Error',
        'windDirection': 'Error',
        'precipitation': 'Error',
      };
    }
  }

  // ... en el build method ...
  ChatbotFloatingWidget(
    weatherData: _weatherData,
  ),
}
```

---

### 💡 Solución 2: Usar Provider o GetX (Para Apps Complejas)

Si usas **Provider**:

```dart
// Crear un ChangeNotifier para los datos meteorológicos
class WeatherProvider extends ChangeNotifier {
  Map<String, dynamic> _weatherData = {};

  Map<String, dynamic> get weatherData => _weatherData;

  Future<void> loadWeatherData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('weather_data')
          .doc('latest')
          .get();

      _weatherData = {
        'temperature': doc['temperature'] ?? 0.0,
        'humidity': doc['humidity'] ?? 0.0,
        'pressure': doc['pressure'] ?? 0.0,
        'windSpeed': doc['windSpeed'] ?? 0.0,
        'windDirection': doc['windDirection'] ?? 0.0,
        'precipitation': doc['precipitation'] ?? 0.0,
      };

      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
  }
}

// En main.dart, envolver con Provider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => WeatherProvider()),
  ],
  child: const WeatherMonitoringApp(),
)

// En main_tab_screen.dart
ChatbotFloatingWidget(
  weatherData: Provider.of<WeatherProvider>(context).weatherData,
),
```

---

### 💡 Solución 3: Escucha en Tiempo Real

Si necesitas actualizar el chatbot en tiempo real:

```dart
@override
void initState() {
  super.initState();
  _listenToWeatherData();
}

void _listenToWeatherData() {
  FirebaseFirestore.instance
      .collection('weather_data')
      .doc('latest')
      .snapshots()
      .listen((snapshot) {
    if (snapshot.exists) {
      setState(() {
        _weatherData = {
          'temperature': snapshot['temperature'] ?? 0.0,
          'humidity': snapshot['humidity'] ?? 0.0,
          'pressure': snapshot['pressure'] ?? 0.0,
          'windSpeed': snapshot['windSpeed'] ?? 0.0,
          'windDirection': snapshot['windDirection'] ?? 0.0,
          'precipitation': snapshot['precipitation'] ?? 0.0,
        };
      });
    }
  });
}
```

---

### 📱 Ejemplo Completo para DataScreen

Si quieres obtener datos de la pantalla de datos actual:

```dart
// lib/screens/data_screen.dart (Ejemplo)

class DataScreen extends StatefulWidget {
  const DataScreen({Key? key}) : super(key: key);

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  late Future<Map<String, dynamic>> weatherDataFuture;

  @override
  void initState() {
    super.initState();
    weatherDataFuture = _fetchWeatherData();
  }

  Future<Map<String, dynamic>> _fetchWeatherData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('weather_stations')
          .doc('your_station_id')
          .get();

      return {
        'temperature': doc['temperature'] ?? 0.0,
        'humidity': doc['humidity'] ?? 0.0,
        'pressure': doc['pressure'] ?? 0.0,
        'windSpeed': doc['windSpeed'] ?? 0.0,
        'windDirection': doc['windDirection'] ?? 0.0,
        'precipitation': doc['precipitation'] ?? 0.0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: weatherDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final data = snapshot.data ?? {};

          return Column(
            children: [
              // ... tus widgets de datos ...

              // Luego, cuando necesites pasar datos al chatbot,
              // puedes usar estos datos
            ],
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
```

---

### 🎯 Actualizar los Contextos del Chatbot

Modifica `google_ai_service.dart` para mejorar el contexto:

```dart
Future<String> getContextualResponse(
  String userQuestion,
  Map<String, dynamic> weatherData,
) async {
  try {
    // Crear descripción inteligente del clima
    String weatherDescription = _generateWeatherDescription(weatherData);

    final contextMessage = '''
Eres un asistente inteligente para una estación meteorológica llamada ENMA (Estación Meteorológica UDEC).
Tu rol es ayudar a los usuarios a entender y analizar los datos climáticos.

Estado Actual de la Estación:
$weatherDescription

Datos Técnicos:
- Temperatura: ${weatherData['temperature']}°C
- Humedad: ${weatherData['humidity']}%
- Presión: ${weatherData['pressure']} hPa
- Velocidad del viento: ${weatherData['windSpeed']} km/h
- Dirección del viento: ${weatherData['windDirection']}°
- Precipitación: ${weatherData['precipitation']} mm

Pregunta del usuario: $userQuestion

Proporciona una respuesta clara, útil y en español.
''';

    final response = await _model.generateContent([
      Content.text(contextMessage),
    ]);

    return response.text ?? 'No se pudo generar una respuesta.';
  } catch (e) {
    return 'Error: ${e.toString()}';
  }
}

String _generateWeatherDescription(Map<String, dynamic> data) {
  final temp = data['temperature'];
  final humidity = data['humidity'];
  final windSpeed = data['windSpeed'];

  String description = 'La estación reporta: ';

  if (temp != null) {
    if (temp > 30) {
      description += 'clima muy caluroso ($temp°C), ';
    } else if (temp > 20) {
      description += 'clima templado ($temp°C), ';
    } else if (temp > 10) {
      description += 'clima frío ($temp°C), ';
    } else {
      description += 'clima muy frío ($temp°C), ';
    }
  }

  if (humidity != null) {
    if (humidity > 80) {
      description += 'ambiente muy húmedo ($humidity%), ';
    } else if (humidity > 60) {
      description += 'ambiente moderadamente húmedo ($humidity%), ';
    } else {
      description += 'ambiente seco ($humidity%), ';
    }
  }

  if (windSpeed != null) {
    if (windSpeed > 50) {
      description += 'vientos muy fuertes ($windSpeed km/h)';
    } else if (windSpeed > 30) {
      description += 'vientos moderados ($windSpeed km/h)';
    } else if (windSpeed > 10) {
      description += 'vientos débiles ($windSpeed km/h)';
    } else {
      description += 'calma, sin vientos significativos';
    }
  }

  return description;
}
```

---

### 🔌 Conexión con Firebase Realtime Database

Si usas Realtime Database:

```dart
Future<Map<String, dynamic>> _fetchWeatherDataRealtime() async {
  try {
    final ref = FirebaseDatabase.instance.ref('weather/latest');
    final event = await ref.once();

    final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};

    return {
      'temperature': data['temperature']?.toDouble() ?? 0.0,
      'humidity': data['humidity']?.toDouble() ?? 0.0,
      'pressure': data['pressure']?.toDouble() ?? 0.0,
      'windSpeed': data['windSpeed']?.toDouble() ?? 0.0,
      'windDirection': data['windDirection']?.toDouble() ?? 0.0,
      'precipitation': data['precipitation']?.toDouble() ?? 0.0,
    };
  } catch (e) {
    return {'error': e.toString()};
  }
}
```

---

### ✅ Checklist de Integración

- [ ] Identificar dónde están almacenados los datos meteorológicos
- [ ] Elegir el método de obtención de datos (Firebase, API local, etc.)
- [ ] Implementar la función `_fetchWeatherData()`
- [ ] Actualizar `main_tab_screen.dart` con los datos reales
- [ ] Probar el chatbot con datos reales
- [ ] Verificar que las respuestas sean contextuales
- [ ] Implementar actualización en tiempo real (opcional)
- [ ] Agregar manejo de errores

---

### 📞 Preguntas Comunes

**P: ¿Cómo obtiene el chatbot acceso a los datos?**
R: Los datos se pasan como un parámetro al widget `ChatbotFloatingWidget`.

**P: ¿Puedo actualizar los datos en tiempo real?**
R: Sí, usando listeners de Firebase o polling periódico.

**P: ¿Qué pasa si no hay datos disponibles?**
R: El chatbot seguirá funcionando pero responderá "N/A" o en modo general.

---

**Última actualización:** 14 de mayo de 2026  
**Compatible con:** ENMA v1.0.0+
