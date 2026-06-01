## 🔒 Configuración de Seguridad - Chatbot ENMA

### ⚠️ Consideraciones de Seguridad Importantes

La clave API de Google Generative AI está actualmente embebida en el código (`google_ai_service.dart`). Para producción, es **CRÍTICO** implementar medidas de seguridad adicionales.

---

### 🛡️ Recomendaciones de Seguridad

#### 1. **No Exponer la Clave API en el Código**

**❌ NUNCA (Actual)**

```dart
static const String _apiKey = 'AIzaSyBu5yxcfDD5DJ4IkZJkxoHirL6OfFgLHY4';
```

**✅ MEJOR: Usar Backend**

```dart
// El backend retorna un token temporal
Future<String> getApiToken() async {
  final response = await http.get('/api/get-ai-token');
  return response.body['token'];
}
```

#### 2. **Implementar Restricciones de API Key**

En Google Cloud Console:

- Restringir por plataforma (Android, iOS, Web)
- Restringir por referer HTTP
- Limitar cuotas y presupuesto
- Implementar rate limiting

#### 3. **Usar Variables de Entorno**

```dart
// .env file (nunca comitear en Git)
GOOGLE_AI_API_KEY=AIzaSyBu5yxcfDD5DJ4IkZJkxoHirL6OfFgLHY4

// En el código
final apiKey = String.fromEnvironment('GOOGLE_AI_API_KEY');
```

#### 4. **Implementar Backend Intermedio**

```
Flutter App
    ↓
Backend Seguro (Node.js/Python)
    ↓
Google API
```

---

### 📋 Checklist de Seguridad Pre-Producción

- [ ] Mover API key a backend seguro
- [ ] Implementar autenticación de usuarios
- [ ] Agregar rate limiting
- [ ] Implementar logging y monitoreo
- [ ] Revisar historial de conversaciones para PII
- [ ] Implementar cifrado de datos en tránsito (HTTPS)
- [ ] Revisar políticas de privacidad de Google AI
- [ ] Implementar tokens JWT para autenticación
- [ ] Agregar validación de entrada en backend
- [ ] Configurar WAF (Web Application Firewall)

---

### 🔄 Migración Recomendada para Producción

#### Paso 1: Crear Backend API

```python
# backend/routes/chat.py
from flask import request, jsonify
from google.generativeai import Client

@app.route('/api/chat', methods=['POST'])
@token_required
def chat():
    message = request.json['message']
    client = Client(api_key=os.environ['GOOGLE_AI_API_KEY'])
    response = client.messages.create(message)
    return jsonify({'response': response.text})
```

#### Paso 2: Actualizar GoogleAIService

```dart
Future<String> sendMessage(String message) async {
  // Obtener token del usuario
  final token = await _getAuthToken();

  // Hacer request al backend
  final response = await http.post(
    'https://api.tudominio.com/api/chat',
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'message': message}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['response'];
  }
  throw Exception('Error: ${response.body}');
}
```

#### Paso 3: Agregar Rate Limiting

```python
from flask_limiter import Limiter
limiter = Limiter(app, key_func=get_remote_address)

@app.route('/api/chat', methods=['POST'])
@limiter.limit("10 per minute")
@token_required
def chat():
    # ... código del chat
```

---

### 🔐 Mejores Prácticas Implementadas

1. **Validación de Entrada**
   - Sanitizar mensajes del usuario
   - Limitar longitud de mensajes
   - Detectar patrones de abuso

2. **Privacidad**
   - No almacenar datos personales identificables
   - Cifrar historial de conversaciones
   - Implementar política de retención de datos

3. **Monitoreo**
   - Loguear todas las solicitudes a la API
   - Alertas para uso anómalo
   - Dashboard de métricas

4. **Autenticación**
   - Requerir login para usar el chatbot
   - Implementar JWT tokens
   - Refresh tokens con expiración

---

### 📊 Estructura de Respuesta Segura

```json
{
  "success": true,
  "data": {
    "message": "Respuesta del chatbot",
    "timestamp": "2026-05-14T10:30:00Z"
  },
  "errors": null
}
```

---

### 🚨 Alertas de Seguridad Comunes

| Alerta              | Causa                | Solución                                    |
| ------------------- | -------------------- | ------------------------------------------- |
| API Key en logs     | Debuging sin filtrar | Usar Firebase Crashlytics con PII filtering |
| Rate limit excedido | Ataque de bots       | Implementar CAPTCHA en backend              |
| Respuestas lentas   | Carga alta           | Implementar caché de respuestas             |
| Errores 401         | Token expirado       | Refresh token automático                    |

---

### 🔗 Enlaces Útiles

- [Google Cloud Console](https://console.cloud.google.com)
- [Documentación Google Generative AI](https://ai.google.dev/)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Flutter Security Best Practices](https://flutter.dev/security)

---

### 📞 Acciones Inmediatas Recomendadas

1. **Para Desarrollo Local:**
   - Usa la configuración actual (está bien para desarrollo)
   - Nunca comitees la API key a repositorios públicos

2. **Para Testing:**
   - Implementa backend mock
   - Usa un proyecto de pruebas en Google Cloud

3. **Para Producción:**
   - Mueve la lógica a backend
   - Implementa todas las medidas de seguridad
   - Realiza auditoría de seguridad

---

**Estado de Seguridad Actual:** ⚠️ DESARROLLO  
**Recomendación:** 🔴 NO USAR EN PRODUCCIÓN SIN CAMBIOS  
**Fecha de Revisión:** 14 de mayo de 2026
