# ENMA UDEC

Aplicación Flutter para visualización y monitoreo de datos meteorológicos en tiempo real, con integración a Firebase y una interfaz pensada para explorar el historial, revisar alertas y administrar preferencias de usuario.

## Características

- Consulta del último registro meteorológico desde Firestore.
- Vista de historial por calendario con marcadores de días con datos.
- Exportación de registros diarios a CSV.
- Gráficas de métricas por día.
- Lista horizontal de registros por hora con detalle expandible.
- Sistema de alertas basado en umbrales de variables meteorológicas.
- Perfil de usuario con preferencias activables desde la app.
- Pantalla de contacto con datos de soporte.
- Diseño adaptable para teléfono, tableta y escritorio.

## Tecnologías usadas

- Flutter
- Dart
- Firebase Auth
- Cloud Firestore
- Table Calendar
- fl_chart
- csv
- path_provider
- font_awesome_flutter

## Requisitos

- Flutter SDK 3.5 o superior.
- Dart 3.5 o superior.
- Cuenta y proyecto de Firebase configurados.
- Un archivo `google-services.json` para Android y la configuración correspondiente para iOS si aplica.

## Configuración del proyecto

1. Clona el repositorio.
2. Instala dependencias:

```bash
flutter pub get
```

3. Verifica la configuración de Firebase en el proyecto.
4. Confirma que existan las reglas de Firestore publicadas para permitir la lectura de la colección `registros_meteorologicos`.

### Estructura esperada en Firestore

La aplicación consume principalmente:

- `registros_meteorologicos`: colección con los documentos meteorológicos.
- `users/{uid}`: documento del usuario autenticado.
- Subcolecciones opcionales como `alerts`, `history` y `climate`.

## Variables y credenciales

Antes de ejecutar la app, revisa lo siguiente:

- `lib/firebase_options.dart` debe apuntar al proyecto correcto.
- `android/app/google-services.json` debe coincidir con el proyecto Firebase.
- Las reglas de Firestore deben permitir la lectura de los datos necesarios.

## Ejecutar la aplicación

### Android, iOS o escritorio

```bash
flutter run
```

### Web

```bash
flutter run -d chrome
```

### Generar compilación web

```bash
flutter build web
```

## Funcionalidades principales

### Datos actuales

Muestra el último documento disponible en Firestore con el valor de cada variable, un ícono representativo y una breve descripción de la medición.

### Calendario

Permite revisar el historial por día, navegar entre fechas, visualizar una serie por métrica y exportar los registros del día seleccionado.

### Alertas

Detecta valores que superan umbrales definidos para temperatura, humedad, presión atmosférica, calidad del aire y gases combustibles.

### Perfil

Incluye configuración rápida de preferencias como notificaciones, reportes semanales y compartición de datos.

### Contacto

Contiene la información de soporte para el proyecto.

## Estructura del proyecto

```text
lib/
	main.dart
	firebase_options.dart
	models/
	screens/
	services/
	utils/
	widgets/
assets/
	images/
android/
ios/
web/
windows/
linux/
macos/
```

## Dependencias principales

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `table_calendar`
- `fl_chart`
- `csv`
- `path_provider`
- `font_awesome_flutter`

## Notas de implementación

- La lectura de Firestore se hace con stream para mantener la interfaz actualizada.
- La exportación CSV funciona de forma distinta según la plataforma para evitar fallos de navegador.
- El diseño es responsivo para adaptarse a pantallas pequeñas y grandes.

## Contribución

Si quieres contribuir al proyecto:

1. Crea una rama nueva.
2. Implementa el cambio.
3. Verifica que la app compile y funcione.
4. Abre un pull request con una descripción clara.

## Licencia

Este proyecto no incluye una licencia explícita. Si vas a publicarlo en un repositorio, agrega una licencia según el uso que vayas a darle.
