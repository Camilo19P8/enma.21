import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:enma_udec/utils/app_colors.dart';
import 'package:enma_udec/services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen();

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool isEditing = false;
  bool _isLoading = false;

  late TextEditingController nameController;
  late TextEditingController bioController;
  late TextEditingController locationController;

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: user?.displayName ?? '');
    bioController =
        TextEditingController(text: 'Observador de clima apasionado');
    locationController = TextEditingController(text: 'Chillán, Chile');
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final currentUser = user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay un usuario autenticado.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    FirestoreService.saveProfileData(
      currentUser.uid,
      displayName: nameController.text.trim(),
      bio: bioController.text.trim(),
      location: locationController.text.trim(),
    ).then((_) async {
      await currentUser.updateDisplayName(nameController.text.trim());
      if (mounted) {
        setState(() {
          _isLoading = false;
          isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perfil actualizado exitosamente'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar el perfil: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: AppColors.darkBgSecondary,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: isEditing
                ? _saveChanges
                : () {
                    setState(() {
                      isEditing = true;
                    });
                  },
          ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isEditing = false;
                  nameController.text = user?.displayName ?? '';
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
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
                      radius: 60,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      backgroundColor: AppColors.primary,
                      child: user?.photoURL == null
                          ? const Icon(
                              FontAwesomeIcons.user,
                              size: 40,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  if (isEditing)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.darkBg,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Información básica
            Text(
              'Información Básica',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            // Nombre
            _buildEditableField(
              label: 'Nombre',
              controller: nameController,
              icon: FontAwesomeIcons.user,
              enabled: isEditing,
            ),
            const SizedBox(height: 12),
            // Email (solo lectura)
            _buildEditableField(
              label: 'Email',
              controller:
                  TextEditingController(text: user?.email ?? 'Sin email'),
              icon: FontAwesomeIcons.envelope,
              enabled: false,
            ),
            const SizedBox(height: 12),
            // Bio
            _buildEditableField(
              label: 'Biografía',
              controller: bioController,
              icon: FontAwesomeIcons.pen,
              enabled: isEditing,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Ubicación
            Text(
              'Ubicación',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: 'Ubicación',
              controller: locationController,
              icon: FontAwesomeIcons.locationDot,
              enabled: isEditing,
            ),
            const SizedBox(height: 24),
            // Preferencias
            Text(
              'Preferencias',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildPreferenceItem(
              title: 'Notificaciones de Alertas',
              subtitle: 'Recibe notificaciones de cambios climáticos',
              enabled: true,
            ),
            _buildPreferenceItem(
              title: 'Reportes Semanales',
              subtitle: 'Resumen semanal de datos climáticos',
              enabled: true,
            ),
            _buildPreferenceItem(
              title: 'Compartir Datos',
              subtitle: 'Permitir que otros usuarios vean tus datos',
              enabled: false,
            ),
            const SizedBox(height: 24),
            // Botón de guardar (solo visible cuando está editando)
            if (isEditing)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveChanges,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'Guardando...' : 'Guardar Cambios',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 16),
        filled: true,
        fillColor: enabled
            ? AppColors.darkBgSecondary.withOpacity(0.5)
            : AppColors.darkBgSecondary,
      ),
      style: TextStyle(
        color: enabled ? AppColors.lightText : AppColors.mediumText,
      ),
    );
  }

  Widget _buildPreferenceItem({
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
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
          Switch(
            value: enabled,
            onChanged: isEditing ? (_) {} : null,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
