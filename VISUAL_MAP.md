# 🗺️ Mapa Visual del Chatbot ENMA

## Estructura General de la Aplicación

```
┌────────────────────────────────────────────────────────────────┐
│                    ENMA WEATHER MONITORING APP                 │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ 🏠 MainTabScreen                                          │ │
│  │ (Pantalla Principal con 5 Pestañas)                      │ │
│  │                                                           │ │
│  │  ┌────────┐ ┌───────┐ ┌────────┐ ┌────────┐ ┌────────┐  │ │
│  │  │ 📅     │ │ ☁️    │ │ ⚠️    │ │ 👤    │ │ 📧    │  │ │
│  │  │Histo   │ │ Datos │ │Alertas│ │Perfil │ │Contacto│  │ │
│  │  │rial    │ │       │ │      │ │       │ │       │  │ │
│  │  └────────┘ └───────┘ └────────┘ └────────┘ └────────┘  │ │
│  │                                                           │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │        [Content Area]                              │  │ │
│  │  │     (Contenido de la pestaña seleccionada)         │  │ │
│  │  │                                                   │  │ │
│  │  │                               [🤖]← Chatbot       │  │ │
│  │  │                          Flotante Azul            │  │ │
│  │  └────────────────────────────────────────────────────┘  │ │
│  │                                                           │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │ Bottom Navigation Bar                              │  │ │
│  │  └────────────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## Flujo del Chatbot

### Paso 1: Usuario Abre el Chat

```
Estado Inicial (Contraído)
    ↓
[Usuario toca el botón 🤖]
    ↓
AnimatedPositioned inicia animación
    ↓
width: 60 → 350
height: 60 → 500
    ↓
ChatbotFloatingWidget se expande
    ↓
Chat visible con mensaje de bienvenida
```

### Paso 2: Usuario Escribe Mensaje

```
[Usuario escribe pregunta]
    ↓
TextField actualiza _messageController
    ↓
[Usuario presiona Enter o botón envío]
    ↓
_sendMessage() se ejecuta
    ↓
setState() agrega ChatMessage(isUserMessage: true)
    ↓
Mensaje aparece en la UI (burbuja azul derecha)
    ↓
_messageController se limpia
    ↓
_isLoading = true (muestra barra de progreso)
```

### Paso 3: GoogleAIService Procesa

```
[ChatbotFloatingWidget.sendMessage]
    ↓
GoogleAIService.getContextualResponse()
    ↓
Crear contexto con datos meteorológicos:
  • Temperatura actual
  • Humedad
  • Presión
  • Velocidad del viento
  • Dirección del viento
  • Precipitación
    ↓
Agregar pregunta del usuario
    ↓
Crear Content.text() con contexto completo
    ↓
await _model.generateContent()
    ↓
[Enviar a Google Generative AI API]
```

### Paso 4: Google Generative AI (Gemini Pro)

```
[Google AI Servers]
    ↓
Procesar con Gemini Pro Model
    ↓
Analizar pregunta + contexto
    ↓
Generar respuesta relevante
    ↓
Retornar respuesta en texto
    ↓
[Respuesta llega a la app]
```

### Paso 5: Mostrar Respuesta

```
[Respuesta recibida]
    ↓
setState() agrega ChatMessage(isUserMessage: false)
    ↓
_isLoading = false (oculta barra de progreso)
    ↓
Mensaje aparece en UI (burbuja gris izquierda)
    ↓
_scrollToBottom() desplaza al último mensaje
    ↓
Usuario ve respuesta completa
```

### Paso 6: Usuario Cierra Chat

```
[Usuario toca botón X]
    ↓
setState() { _isExpanded = false }
    ↓
AnimatedContainer contrae
    ↓
width: 350 → 60
height: 500 → 60
    ↓
Vuelve a botón flotante inicial
```

---

## Arquitectura de Capas

```
┌─────────────────────────────────────────────────────────┐
│                    UI LAYER                             │
│  ┌───────────────────────────────────────────────────┐  │
│  │ ChatbotFloatingWidget                             │  │
│  │ • AnimatedPositioned                              │  │
│  │ • AnimatedContainer                               │  │
│  │ • ListView (mensajes)                             │  │
│  │ • TextField (input)                               │  │
│  │ • Botones (enviar, cerrar)                        │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ Llamadas
┌─────────────────────────────────────────────────────────┐
│                  SERVICE LAYER                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │ GoogleAIService                                   │  │
│  │ • Gestiona GenerativeModel                        │  │
│  │ • Mantiene ChatSession                            │  │
│  │ • Procesa mensajes                                │  │
│  │ • Agrega contexto meteorológico                   │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ HTTP Request
┌─────────────────────────────────────────────────────────┐
│               GOOGLE API LAYER                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Google Generative AI (Gemini Pro)                 │  │
│  │ • URL: https://generativelanguage.googleapis.com  │  │
│  │ • Model: gemini-pro                               │  │
│  │ • API Key: [Configurada]                          │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Gestión de Estado

### Estados del Widget

```
_ChatbotFloatingWidgetState

├── _isExpanded: bool
│   ├── false → Botón contraído (60x60)
│   └── true  → Chat expandido (350x500)
│
├── _messages: List<ChatMessage>
│   ├── Historial de conversación
│   ├── ChatMessage(text, isUserMessage, timestamp)
│   └── Se mantiene durante la sesión
│
├── _isLoading: bool
│   ├── false → Listo para enviar
│   └── true  → Esperando respuesta
│
├── _messageController: TextEditingController
│   ├── Contiene el texto del usuario
│   └── Se limpia después de enviar
│
└── _scrollController: ScrollController
    ├── Mantiene scroll en el chat
    └── Se desplaza al nuevo mensaje
```

---

## Flujo de Datos

```
Usuario Input
    ↓
[TextField]
    ↓
_messageController.text
    ↓
_sendMessage()
    ↓
Crear ChatMessage(user)
    ↓
setState() → UI actualiza
    ↓
GoogleAIService.getContextualResponse()
    ↓
API Google + context data
    ↓
Respuesta string
    ↓
Crear ChatMessage(bot)
    ↓
setState() → UI actualiza
    ↓
Usuario ve respuesta
```

---

## Mapeo de Archivos

```
📦 ENMA UDEC
│
├── 📄 pubspec.yaml
│   └── ✏️ Agregada: google_generative_ai: ^0.4.2
│
├── 📁 lib/
│   │
│   ├── 📁 services/
│   │   ├── 📄 google_ai_service.dart ✨ NUEVO
│   │   │   ├── GoogleAIService class
│   │   │   ├── sendMessage()
│   │   │   ├── getContextualResponse()
│   │   │   └── resetChat()
│   │   │
│   │   └── [otros servicios...]
│   │
│   ├── 📁 widgets/
│   │   ├── 📄 chatbot_floating_widget.dart ✨ NUEVO
│   │   │   ├── ChatbotFloatingWidget
│   │   │   ├── ChatMessage class
│   │   │   ├── _sendMessage()
│   │   │   ├── _scrollToBottom()
│   │   │   └── UI completa
│   │   │
│   │   └── [otros widgets...]
│   │
│   ├── 📁 screens/
│   │   ├── 📄 main_tab_screen.dart ✏️ MODIFICADO
│   │   │   └── Agregado: ChatbotFloatingWidget en Stack
│   │   │
│   │   └── [otras pantallas...]
│   │
│   └── main.dart
│
└── 📁 Documentación/
    ├── 📄 CHATBOT_README.md ✨ NUEVO
    ├── 📄 CHATBOT_GUIDE.md ✨ NUEVO
    ├── 📄 INTEGRATION_GUIDE.md ✨ NUEVO
    ├── 📄 SECURITY_GUIDE.md ✨ NUEVO
    ├── 📄 ADVANCED_FEATURES.md ✨ NUEVO
    └── 📄 QUICKSTART.md ✨ NUEVO
```

---

## Componentes Visuales

### Botón Contraído

```
┌──────────┐
│   🤖    │ ← 60x60 px
│ (robot)  │   Azul primario
└──────────┘   Con sombra
```

### Chat Expandido

```
┌──────────────────────────────────┐
│ ← ENMA Chat              ✕       │ ← Header (azul)
├──────────────────────────────────┤
│ ¡Hola! Soy tu asistente ENMA     │ ← Mensaje bot (gris)
│ ¿Qué quieres saber?              │
│                                  │
│                      ¿Cuál es la  │ ← Mensaje usuario (azul)
│                    temperatura?   │
│                                  │
│ La temperatura actual es...       │ ← Mensaje bot (gris)
│                                  │
│ ▓▓▓▓▓▓▓▓▓▓▓░░░ Cargando...        │ ← Indicador (si carga)
├──────────────────────────────────┤
│ ┌──────────────────────────────┐ │ ← Input
│ │ Escribe tu pregunta...     │▶│ │
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
```

---

## Interacciones

### Usuario - UI

```
[Toca 🤖] → _isExpanded = true → AnimatedContainer expande
     ↓
[Escribe texto] → TextEditingController.text actualiza
     ↓
[Presiona Enter] → _sendMessage() ejecuta
     ↓
[Toca botón X] → _isExpanded = false → AnimatedContainer contrae
```

### UI - Servicio

```
ChatbotFloatingWidget → GoogleAIService
   _sendMessage()     →    sendMessage()
                     →    getContextualResponse()
```

### Servicio - API

```
GoogleAIService → Google Generative AI
   _model.generateContent() → Gemini Pro API
   HTTP Request            → Response JSON
```

---

## Ciclo de Vida

### Iniciación

```
MainTabScreen crea Stack
    ↓
Stack contiene Scaffold + ChatbotFloatingWidget
    ↓
ChatbotFloatingWidget.initState()
    ↓
GoogleAIService() inicializa
    ↓
GenerativeModel("gemini-pro", apiKey)
    ↓
ChatSession comienza
    ↓
Mensaje de bienvenida agregado
    ↓
Widget renderiza botón 60x60
```

### Durante la Sesión

```
Usuario interactúa
    ↓
Mensajes se agregan a _messages List
    ↓
setState() actualiza UI
    ↓
Widget re-renderiza con nuevos mensajes
```

### Dispose

```
Usuario minimiza/cierra app
    ↓
_ChatbotFloatingWidgetState.dispose()
    ↓
_messageController.dispose()
    ↓
_scrollController.dispose()
    ↓
Historial se pierde (guardar en Firebase para persistencia)
```

---

## Flujo de Datos Completo

```
Usuario                                                  Google API
   │
   ├─→ [Escribe mensaje]
   │       │
   │       └─→ TextField → _messageController
   │
   ├─→ [Presiona Enter]
   │       │
   │       └─→ _sendMessage()
   │           ├─→ Agregar ChatMessage(usuario)
   │           ├─→ setState() → UI actualiza
   │           ├─→ _messageController.clear()
   │           ├─→ _isLoading = true
   │           │
   │           └─→ GoogleAIService.getContextualResponse()
   │               ├─→ Crear contexto con weatherData
   │               ├─→ Construir Content.text()
   │               ├─→ await _model.generateContent()
   │               │        │
   │               │        └──────→ [Google Generative AI API]
   │               │                     │
   │               │                     └─→ Gemini Pro Procesa
   │               │                         ├─→ Analiza pregunta
   │               │                         ├─→ Usa contexto
   │               │                         └─→ Genera respuesta
   │               │                             │
   │               │        ←─────────────────────┘
   │               │
   │               └─→ response.text retorna
   │
   ├─→ [Recibe respuesta]
   │       │
   │       └─→ setState()
   │           ├─→ Agregar ChatMessage(bot)
   │           ├─→ _isLoading = false
   │           ├─→ UI actualiza con respuesta
   │           └─→ _scrollToBottom()
   │
   └─→ [Ve respuesta]
```

---

## Versiones Compatibles

```
flutter: ^3.5.0
google_generative_ai: ^0.4.2
firebase_core: ^2.27.0
font_awesome_flutter: ^10.1.0
```

---

## Diagrama de Clases

```
ChatbotFloatingWidget (StatefulWidget)
    │
    └── _ChatbotFloatingWidgetState
        │
        ├── Properties:
        │   ├── bool _isExpanded
        │   ├── GoogleAIService _aiService
        │   ├── TextEditingController _messageController
        │   ├── List<ChatMessage> _messages
        │   ├── bool _isLoading
        │   └── ScrollController _scrollController
        │
        ├── Methods:
        │   ├── void initState()
        │   ├── void _scrollToBottom()
        │   ├── Future<void> _sendMessage()
        │   ├── Widget build()
        │   └── void dispose()
        │
        └── Widget Structure:
            └── Stack
                └── AnimatedPositioned
                    └── AnimatedContainer
                        ├── (Contraído) GestureDetector
                        │   └── Container (60x60)
                        │       └── Icon(robot)
                        │
                        └── (Expandido) Column
                            ├── Header Container
                            │   └── Row(título, close)
                            ├── Expanded ListView
                            │   └── ChatMessage widgets
                            ├── LinearProgressIndicator
                            └── Input Row
                                ├── TextField
                                └── GestureDetector(send)


ChatMessage (Class)
    ├── String text
    ├── bool isUserMessage
    └── DateTime timestamp


GoogleAIService (Class)
    ├── static const String _apiKey
    ├── static const String _modelName
    ├── late GenerativeModel _model
    ├── late ChatSession _chatSession
    │
    ├── Methods:
    │   ├── void _initializeModel()
    │   ├── Future<String> sendMessage()
    │   ├── Future<String> getContextualResponse()
    │   └── void resetChat()
```

---

**Este mapa visual te ayuda a entender cómo todo funciona junto. ¡Consulta cuando tengas dudas!** 🗺️
