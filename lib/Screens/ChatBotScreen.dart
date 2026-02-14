// Screens/ChatBotScreen.dart
import 'package:flutter/material.dart';
import '../Colors/theme.dart';
import '../widgets/FeatureGate.dart';
import '../widgets/UpgradePrompt.dart';

class ChatBotScreen extends StatelessWidget {
  const ChatBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryLight, Colors.white],
        ),
      ),
      child: FeatureGate(
        featureName: 'ai_chatbot',
        child: const _ChatBotContent(),
        fallback: const UpgradePrompt(
          featureName: 'AI Chat Bot',
          description: 'Get personalized medication advice and answers to your health questions',
        ),
      ),
    );
  }
}

class _ChatBotContent extends StatefulWidget {
  const _ChatBotContent();

  @override
  State<_ChatBotContent> createState() => __ChatBotContentState();
}

class __ChatBotContentState extends State<_ChatBotContent> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'type': 'user',
        'message': _messageController.text.trim(),
      });
    });

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({
          'type': 'bot',
          'message': _getBotResponse(_messageController.text.trim()),
        });
      });
      _scrollToBottom();
    });

    _messageController.clear();
    _scrollToBottom();
  }

  String _getBotResponse(String message) {
    // Simple mock responses - replace with actual AI integration
    if (message.toLowerCase().contains('headache')) {
      return 'For headaches, it\'s important to rest and stay hydrated. You might consider over-the-counter pain relievers like ibuprofen or paracetamol. If headaches persist, please consult a doctor.';
    } else if (message.toLowerCase().contains('fever')) {
      return 'If you have a fever, rest and drink plenty of fluids. You can take acetaminophen or ibuprofen. Monitor your temperature and seek medical attention if it exceeds 103°F (39.4°C) or persists for more than 3 days.';
    } else if (message.toLowerCase().contains('medication')) {
      return 'Always take medications as prescribed. Set reminders for your doses and never skip them. If you experience side effects, contact your healthcare provider immediately.';
    } else {
      return 'Thank you for your question. While I can provide general information, please consult with a healthcare professional for specific medical advice. Is there anything specific about medications or symptoms you\'d like to know?';
    }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.chat, color: Colors.blue),
              ),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medicata AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ask me anything about medications',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(15),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['type'] == 'user';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      const CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.android, size: 15, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.accentLight : Colors.grey[200],
                          borderRadius: BorderRadius.circular(15).copyWith(
                            bottomLeft: isUser ? const Radius.circular(15) : const Radius.circular(5),
                            bottomRight: isUser ? const Radius.circular(5) : const Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          msg['message']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 8),
                      const CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.person, size: 15, color: Colors.white),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        
        // Input field
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.accentLight,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}