import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:enma_udec/utils/app_colors.dart';
import 'package:enma_udec/services/firestore_service.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final currentUser = user;

    if (currentUser == null) {
      return _buildEmptyState(
          context, 'Debes iniciar sesión para ver tu perfil');
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.profileStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildEmptyState(
            context,
            'No fue posible cargar el perfil desde Firestore',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data();
        if (data == null) {
          return _buildEmptyState(
            context,
            'No existe un perfil guardado para este usuario',
          );
        }

        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        final preferences = data['preferences'] as Map<String, dynamic>? ?? {};
        final displayName =
            (data['displayName'] as String?)?.trim().isNotEmpty == true
                ? data['displayName'] as String
                : (currentUser.displayName ?? 'Usuario');
        final email = (data['email'] as String?)?.trim().isNotEmpty == true
            ? data['email'] as String
            : (currentUser.email ?? 'Sin correo');
        final photoUrl = (data['photoUrl'] as String?) ?? currentUser.photoURL;
        final location =
            (data['location'] as String?)?.trim().isNotEmpty == true
                ? data['location'] as String
                : 'Sin ubicación registrada';
        final bio = (data['bio'] as String?)?.trim().isNotEmpty == true
            ? data['bio'] as String
            : 'Sin biografía registrada';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.12),
                      AppColors.accent.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundImage:
                            (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                        backgroundColor: AppColors.primary,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? const Icon(
                                FontAwesomeIcons.user,
                                size: 28,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.mediumText,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            location,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.lightText,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                bio,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mediumText,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tus estadísticas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatTile(
                    context,
                    icon: FontAwesomeIcons.eye,
                    title: 'Observaciones',
                    value: _formatStatValue(stats['observations']),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildStatTile(
                    context,
                    icon: FontAwesomeIcons.bell,
                    title: 'Alertas',
                    value: _formatStatValue(stats['alerts']),
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  _buildStatTile(
                    context,
                    icon: FontAwesomeIcons.calendar,
                    title: 'Días activo',
                    value: _formatStatValue(stats['activeDays']),
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Configuración',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildPreferenceToggle(
                context,
                uid: currentUser.uid,
                icon: FontAwesomeIcons.bell,
                title: 'Notificaciones',
                prefKey: 'notifications',
                value: preferences['notifications'] as bool? ?? true,
              ),
              _buildPreferenceToggle(
                context,
                uid: currentUser.uid,
                icon: FontAwesomeIcons.chartLine,
                title: 'Reportes semanales',
                prefKey: 'weeklyReports',
                value: preferences['weeklyReports'] as bool? ?? true,
              ),
              _buildPreferenceToggle(
                context,
                uid: currentUser.uid,
                icon: FontAwesomeIcons.shieldHalved,
                title: 'Compartir datos',
                prefKey: 'shareData',
                value: preferences['shareData'] as bool? ?? false,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.pen),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      label: const Text('Editar perfil'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.signOut),
                      onPressed: () => _showLogoutDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      label: const Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'ENMA v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText,
                      ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: AppColors.mediumText,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkBgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkBgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mediumText,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.mediumText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceToggle(
    BuildContext context, {
    required String uid,
    required IconData icon,
    required String title,
    required String prefKey,
    required bool value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkBgSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Switch(
              value: value,
              activeColor: AppColors.primary,
              onChanged: (newVal) async {
                try {
                  await FirestoreService.updateUserPreference(
                      uid, prefKey, newVal);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            newVal ? '$title activado' : '$title desactivado'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error actualizando $title'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatValue(dynamic value) {
    if (value == null) {
      return '--';
    }

    final text = value.toString().trim();
    return text.isEmpty ? '--' : text;
  }

  String _asReadablePreference(
    dynamic value, {
    required String enabledText,
    required String disabledText,
  }) {
    if (value == null) {
      return 'Sin configuración';
    }

    if (value is bool) {
      return value ? enabledText : disabledText;
    }

    return value.toString();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
