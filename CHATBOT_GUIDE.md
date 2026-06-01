## 🤖 Guía del Chatbot ENMA

### Descripción General

El chatbot ENMA es un asistente inteligente impulsado por Google Generative AI (Gemini Pro) que te permite hacer consultas y preguntas sobre la plataforma de monitoreo meteorológico directamente desde la aplicación.

### Características Principales

✅ **Botón Flotante Interactivo**

- Acceso rápido desde cualquier pantalla de la aplicación
- Se puede expandir y contraer fácilmente
- Diseño moderno e integrado con el tema oscuro de la app

✅ **Conversaciones Contextuales**

- El chatbot tiene acceso a los datos meteorológicos en tiempo real
- Proporciona respuestas inteligentes basadas en el contexto climático
- Mantiene el historial de conversaciones

✅ **Interfaz Amigable**

- Interfaz de chat clásica con burbujas de mensajes
- Diferenciación visual entre mensajes del usuario y del asistente
- Indicador de carga mientras se procesa la respuesta
- Scroll automático a los mensajes más recientes

---

### Cómo Usar el Chatbot

#### 1. **Abre el Chat**

- Haz clic en el botón flotante azul con el ícono del robot (esquina inferior derecha)
- La ventana del chat se expandirá mostrando el historial de conversación

#### 2. **Escribe tu Pregunta**

- Escribe tu pregunta en el campo de entrada en la parte inferior del chat
- Puedes presionar "Enter" o hacer clic en el botón de envío (avión de papel)

#### 3. **Obtén Respuestas**

- El chatbot procesará tu pregunta usando Google Generative AI
- Verás la respuesta en la ventana del chat

#### 4. **Cierra el Chat**

- Haz clic en el botón "X" en la esquina superior derecha del chat
- O simplemente haz clic fuera del chat (si implementas esa funcionalidad)

---

### Ejemplos de Consultas

**Datos Meteorológicos:**

- "¿Cuál es la temperatura actual?"
- "¿Está muy húmedo el ambiente?"
- "¿Cómo está el viento?"
- "¿Hay riesgo de lluvia?"

**Sobre la Plataforma:**

- "¿Cómo uso el calendario?"
- "¿Qué significan las alertas?"
- "¿Cómo genero un reporte?"
- "¿Cuál es la funcionalidad de contacto?"

**Análisis de Datos:**

- "¿Cuál es la tendencia de temperatura?"
- "¿Está dentro de los parámetros normales?"
- "¿Qué recomendaciones tienes?"

---

### Arquitectura del Chatbot

#### 📁 Archivos Creados

1. **`lib/services/google_ai_service.dart`**
   - Servicio principal que maneja la comunicación con la API de Google
   - Métodos:
     - `sendMessage()`: Envía un mensaje simple
     - `getContextualResponse()`: Obtiene respuestas considerando datos meteorológicos
     - `resetChat()`: Reinicia la conversación

2. **`lib/widgets/chatbot_floating_widget.dart`**
   - Widget flotante que proporciona la interfaz del chat
   - Características:
     - Animaciones suave de expansión/contracción
     - Gestión del historial de mensajes
     - Indicador de carga
     - Integración con el servicio de IA

3. **`lib/screens/main_tab_screen.dart` (modificado)**
   - Integración del chatbot flotante en la pantalla principal
   - El chatbot está disponible en todas las pestañas

---

### Configuración Técnica

#### Dependencias Necesarias

```yaml
google_generative_ai: ^0.4.2
```

#### Clave API

La clave API de Google Generative AI está configurada en:

```dart
static const String _apiKey = 'AIzaSyBu5yxcfDD5DJ4IkZJkxoHirL6OfFgLHY4';
```

**Nota de Seguridad:** En producción, considera:

- Almacenar la clave en un archivo de configuración seguro
- Usar variables de entorno
- Implementar autenticación en el backend

---

### Flujo de Funcionamiento

```
Usuario escribe pregunta
        ↓
GoogleAIService recibe la pregunta
        ↓
Se agrega contexto de datos meteorológicos (opcional)
        ↓
Se envía a la API de Google Generative AI
        ↓
Se recibe y procesa la respuesta
        ↓
Se muestra en la interfaz del chat
        ↓
Historial se mantiene para referencias futuras
```

---

### Personalización y Mejoras Futuras

#### 🔧 Posibles Mejoras

1. **Persistencia de Datos**
   - Guardar historial de conversaciones en Firebase
   - Recuperar conversaciones anteriores

2. **Temas Avanzados**
   - Integración con análisis predictivo
   - Recomendaciones basadas en IA
   - Alertas inteligentes

3. **Multiidioma**
   - Soporte para otros idiomas además del español

4. **Exportación de Datos**
   - Descargar historial de conversaciones
   - Generar reportes basados en análisis del chatbot

5. **Voz**
   - Entrada por voz
   - Respuestas de audio

---

### Solución de Problemas

#### ❌ El chatbot no responde

- Verifica tu conexión a internet
- Revisa que la clave API sea válida
- Comprueba los logs de la consola para mensajes de error

#### ❌ Respuestas lentas

- La API de Google puede tardar 2-5 segundos
- Verifica la velocidad de tu conexión
- Considera usar cachés para respuestas frecuentes

#### ❌ Errores de configuración

- Asegúrate de haber ejecutado `flutter pub get`
- Verifica que todos los archivos estén en la ubicación correcta
- Revisa que no haya conflictos con otras dependencias

---

### Variables de Personalización

En `lib/widgets/chatbot_floating_widget.dart` puedes personalizar:

```dart
// Tamaño del chat
width: _isExpanded ? 350 : 60,
height: _isExpanded ? 500 : 60,

// Colores y bordes
backgroundColor: AppColors.darkBgSecondary,
border: Border.all(color: AppColors.primary.withOpacity(0.5)),

// Textos
'¡Hola! Soy tu asistente ENMA...'
'Escribe tu pregunta...'
```

---

### Integración con Datos Meteorológicos

El chatbot puede acceder a datos meteorológicos para proporcionar respuestas más precisas:

```dart
ChatbotFloatingWidget(
  weatherData: {
    'temperature': currentTemp,
    'humidity': currentHumidity,
    'pressure': currentPressure,
    'windSpeed': currentWindSpeed,
    'windDirection': currentWindDirection,
    'precipitation': currentPrecipitation,
  },
)
```

---

### Soporte y Contacto

Si tienes preguntas o problemas con el chatbot:

1. Revisa la sección de "Contacto" en la aplicación
2. Consulta la documentación de Google Generative AI
3. Verifica los logs de la aplicación

---

**Versión:** 1.0.0  
**Última actualización:** 14 de mayo de 2026  
**Estado:** ✅ Funcional
