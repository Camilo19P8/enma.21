import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:enma_udec/screens/login_screen.dart';
import 'package:enma_udec/services/groq_chat_service.dart';
import 'package:enma_udec/utils/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If the local .env file is missing, the app still boots and can fall back to dart-define.
  }
  await GroqChatService.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WeatherMonitoringApp());
}

class WeatherMonitoringApp extends StatelessWidget {
  const WeatherMonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ENMA - Monitoreo Climático',
      theme: AppTheme.darkTheme(),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
