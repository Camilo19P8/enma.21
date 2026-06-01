import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:enma_udec/utils/app_colors.dart';

class ContactScreen extends StatefulWidget {
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Consulta General';
  bool _isLoading = false;

  final List<String> _categories = [
    'Consulta General',
    'Soporte Técnico',
    'Reportar Error',
    'Sugerencias',
    'Colaboración',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simular envío
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Mensaje enviado exitosamente!'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          _nameController.clear();
          _emailController.clear();
          _messageController.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Text(
            'Ponte en Contacto',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Nos encantaría escuchar de ti. Envía tu mensaje y te responderemos pronto.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mediumText,
                ),
          ),
          const SizedBox(height: 24),
          // Información de contacto
          Row(
            children: [
              _buildContactInfo(
                icon: FontAwesomeIcons.envelope,
                title: 'Email',
                value: 'enmasoporte@gmail.com',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _buildContactInfo(
                icon: FontAwesomeIcons.phone,
                title: 'Teléfono',
                value: '3228405783',
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Formulario
          Text(
            'Formulario de Contacto',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tu Nombre',
                    hintText: 'Ej: Juan Pérez',
                    prefixIcon: const Icon(FontAwesomeIcons.user, size: 16),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Tu Email',
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: const Icon(FontAwesomeIcons.envelope, size: 16),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor ingresa tu email';
                    }
                    if (!value!.contains('@')) {
                      return 'Por favor ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Categoría
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.darkBgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.darkBgSecondary,
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Mensaje
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Tu Mensaje',
                    hintText: 'Cuéntanos qué necesitas...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Icon(FontAwesomeIcons.message, size: 16),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor ingresa tu mensaje';
                    }
                    if (value!.length < 10) {
                      return 'El mensaje debe tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Botón de envío
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sendMessage,
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
                        : const Icon(FontAwesomeIcons.paperPlane),
                    label: Text(
                      _isLoading ? 'Enviando...' : 'Enviar Mensaje',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Redes sociales
          Text(
            'Síguenos en Redes Sociales',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkBgSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialButton(
                      icon: FontAwesomeIcons.facebook,
                      label: 'Facebook',
                      color: const Color(0xFF1877F2),
                      onTap: () {},
                    ),
                    _buildSocialButton(
                      icon: FontAwesomeIcons.twitter,
                      label: 'Twitter',
                      color: const Color(0xFF1DA1F2),
                      onTap: () {},
                    ),
                    _buildSocialButton(
                      icon: FontAwesomeIcons.instagram,
                      label: 'Instagram',
                      color: const Color(0xFFE4405F),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialButton(
                      icon: FontAwesomeIcons.linkedin,
                      label: 'LinkedIn',
                      color: const Color(0xFF0A66C2),
                      onTap: () {},
                    ),
                    _buildSocialButton(
                      icon: FontAwesomeIcons.youtube,
                      label: 'YouTube',
                      color: const Color(0xFFFF0000),
                      onTap: () {},
                    ),
                    _buildSocialButton(
                      icon: FontAwesomeIcons.github,
                      label: 'GitHub',
                      color: const Color(0xFF333333),
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Información adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.circleInfo,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tiempo de Respuesta',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Responderemos tu mensaje dentro de 24 horas laborales. Si es urgente, por favor llamanos al número de teléfono anterior.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumText,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContactInfo({
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumText,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
