// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:enma_udec/utils/app_colors.dart';
import 'package:enma_udec/services/groq_chat_service.dart';

class ChatbotFloatingWidget extends StatefulWidget {
  final Map<String, dynamic>? weatherData;

  const ChatbotFloatingWidget({
    super.key,
    this.weatherData,
  });

  @override
  State<ChatbotFloatingWidget> createState() => _ChatbotFloatingWidgetState();
}

class _ChatbotFloatingWidgetState extends State<ChatbotFloatingWidget> {
  bool _isExpanded = false;
  late GroqChatService _aiService;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasAddedWelcomeMessage = false;

  bool get _isEnglishLocale {
    final languageCode =
        Localizations.localeOf(context).languageCode.toLowerCase();
    return languageCode.startsWith('en');
  }

  String get _welcomeMessage {
    if (_isEnglishLocale) {
      return 'Hi! I am your ENMA assistant. I can help with weather data and the platform. What would you like to know?';
    }

    return '¡Hola! Soy tu asistente ENMA. Puedo ayudarte con los datos meteorológicos y la plataforma. ¿Qué quieres saber?';
  }

  String get _hintText {
    return _isEnglishLocale
        ? 'Type your question...'
        : 'Escribe tu pregunta...';
  }

  String get _headerTitle {
    return _isEnglishLocale ? 'ENMA Chat' : 'Chat ENMA';
  }

  String get _errorMessage {
    return _isEnglishLocale
        ? 'Error: Could not process your message. Please try again.'
        : 'Error: No se pudo procesar tu mensaje. Intenta de nuevo.';
  }

  @override
  void initState() {
    super.initState();
    _aiService = GroqChatService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAddedWelcomeMessage) {
      return;
    }

    _messages.add(
      ChatMessage(
        text: _welcomeMessage,
        isUserMessage: false,
      ),
    );
    _hasAddedWelcomeMessage = true;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Agregar mensaje del usuario
    setState(() {
      _messages.add(
        ChatMessage(
          text: message,
          isUserMessage: true,
        ),
      );
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      String response;

      // Si hay datos meteorológicos, usar respuesta contextual
      if (widget.weatherData != null && widget.weatherData!.isNotEmpty) {
        response = await _aiService.getContextualResponse(
          message,
          widget.weatherData!,
        );
      } else {
        response = await _aiService.sendMessage(message);
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: response,
            isUserMessage: false,
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: _errorMessage,
            isUserMessage: false,
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: 16,
      bottom: 16,
      width: _isExpanded ? 350 : 60,
      height: _isExpanded ? 500 : 60,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppColors.darkBgSecondary,
          borderRadius: BorderRadius.circular(_isExpanded ? 16 : 30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: _isExpanded
            ? Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    // Header del chat
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                _headerTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final pasted = await showDialog<String>(
                                    context: context,
                                    builder: (context) {
                                      final ctl = TextEditingController();
                                      return AlertDialog(
                                        title: const Text('Pegar Groq API Key'),
                                        content: TextField(
                                          controller: ctl,
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Pega aquí la Groq API key',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                context, ctl.text.trim()),
                                            child: const Text('Guardar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (pasted != null && pasted.isNotEmpty) {
                                    final messenger =
                                        ScaffoldMessenger.maybeOf(context);
                                    await _aiService.setRuntimeApiKey(pasted);
                                    if (!mounted) return;
                                    messenger?.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Groq API key guardada y persistida localmente.',
                                        ),
                                      ),
                                    );
                                    setState(() {
                                      _messages.add(
                                        ChatMessage(
                                          text: _isEnglishLocale
                                              ? 'Groq API key saved and stored locally. Restarting the app will keep it.'
                                              : 'Clave Groq guardada y persistida localmente. Al reiniciar la app seguirá disponible.',
                                          isUserMessage: false,
                                        ),
                                      );
                                    });
                                  }
                                },
                                child: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = false;
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Lista de mensajes
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: message.isUserMessage
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: message.isUserMessage
                                      ? AppColors.primary
                                      : AppColors.darkBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: message.isUserMessage
                                      ? null
                                      : Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                        ),
                                ),
                                constraints:
                                    const BoxConstraints(maxWidth: 250),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    color: message.isUserMessage
                                        ? Colors.white
                                        : AppColors.lightText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Indicador de carga
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          height: 20,
                          child: LinearProgressIndicator(
                            backgroundColor: AppColors.darkBg,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    // Input de mensajes
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                hintText: _hintText,
                                hintStyle: TextStyle(
                                  color: AppColors.lightText
                                      .withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              onSubmitted: (_) {
                                if (!_isLoading) {
                                  _sendMessage();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: !_isLoading ? _sendMessage : null,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                FontAwesomeIcons.paperPlane,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = true;
                  });
                  _scrollToBottom();
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.robot,
                          color: Colors.white,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
