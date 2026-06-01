import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:enma_udec/utils/app_colors.dart';
import 'package:enma_udec/widgets/chatbot_floating_widget.dart';
import 'calendar_screen.dart';
import 'data_screen.dart';
import 'profile_screen.dart';
import 'alerts_screen.dart';
import 'contact_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen();

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  late final List<Widget> _children = [
    CalendarScreen(),
    DataScreen(),
    AlertsScreen(),
    ProfileScreen(),
    ContactScreen(),
  ];

  late final List<String> _titles = [
    'Historial',
    'Datos Actuales',
    'Alertas',
    'Perfil',
    'Contacto',
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              _titles[_currentIndex],
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 24,
                  ),
            ),
            backgroundColor: AppColors.darkBgSecondary,
            elevation: 2,
            actions: [
              // Indicador de estado de conexión
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Tooltip(
                    message: 'Estación en línea',
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'En línea',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _children,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.darkBgSecondary,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.mediumText,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                activeIcon: Icon(Icons.calendar_month),
                label: 'Historial',
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.cloudSun),
                activeIcon: Icon(FontAwesomeIcons.cloudSun),
                label: 'Datos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                activeIcon: Icon(Icons.notifications),
                label: 'Alertas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mail),
                activeIcon: Icon(Icons.mail),
                label: 'Contacto',
              ),
            ],
          ),
        ),
        // Chatbot flotante
        ChatbotFloatingWidget(
          weatherData: {
            'temperature': 'N/A',
            'humidity': 'N/A',
            'pressure': 'N/A',
            'windSpeed': 'N/A',
            'windDirection': 'N/A',
            'precipitation': 'N/A',
          },
        ),
      ],
    );
  }
}
