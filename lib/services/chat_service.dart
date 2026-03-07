import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // System prompt to define the chatbot's personality and knowledge area
  static const String _systemPrompt = '''
You are MediCare AI Assistant, a helpful and friendly healthcare companion for the Medicata app. 
Your role is to provide general information about medications, health tips, and answer questions 
related to healthcare in a supportive, empathetic manner.

Guidelines:
1. Always remind users to consult healthcare professionals for medical advice
2. Be clear about medication safety and potential interactions
3. Maintain a warm, caring tone with occasional emojis when appropriate
4. Keep responses concise but informative (under 300 words)
5. For emergencies, always advise seeking immediate medical attention
6. You can help with:
   - Medication information and reminders
   - General health and wellness tips
   - Understanding prescriptions
   - Symptom guidance (non-emergency)
   - Lifestyle and healthy habits

Remember: You're an AI assistant, not a doctor. Always include appropriate disclaimers.
''';

  Future<ChatMessage> sendMessage(
    String userMessage,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      // Prepare messages array with system prompt and conversation history
      List<Map<String, String>> messages = [
        {'role': 'system', 'content': _systemPrompt},
      ];

      // Add last few messages from history for context (max 10 to avoid token limits)
      final recentHistory = conversationHistory.length > 10
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory;

      for (var msg in recentHistory) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.message,
        });
      }

      // Add current user message
      messages.add({'role': 'user', 'content': userMessage});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
          'top_p': 1,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];

        return ChatMessage(
          message: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return ChatMessage(
          message:
              'I apologize, but I\'m having trouble connecting right now. Please try again in a moment. 🙏',
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      print('Chat Service Error: $e');
      return ChatMessage(
        message:
            'Oops! Something went wrong. Please check your connection and try again. 🔌',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  // Alternative method for streaming responses (more advanced)
  Stream<ChatMessage> streamMessage(
    String userMessage,
    List<ChatMessage> conversationHistory,
  ) async* {
    try {
      List<Map<String, String>> messages = [
        {'role': 'system', 'content': _systemPrompt},
      ];

      final recentHistory = conversationHistory.length > 10
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory;

      for (var msg in recentHistory) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.message,
        });
      }

      messages.add({'role': 'user', 'content': userMessage});

      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 500,
        'stream': true,
      });

      final response = await request.send();

      if (response.statusCode == 200) {
        String fullResponse = '';
        await for (var chunk
            in response.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          if (chunk.startsWith('data: ')) {
            final data = chunk.substring(6);
            if (data == '[DONE]') continue;

            try {
              final jsonData = jsonDecode(data);
              final content = jsonData['choices'][0]['delta']['content'];
              if (content != null) {
                fullResponse += content;
                yield ChatMessage(
                  message: fullResponse,
                  isUser: false,
                  timestamp: DateTime.now(),
                  isStreaming: true,
                );
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      } else {
        yield ChatMessage(
          message: 'Connection error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      yield ChatMessage(
        message: 'Network error. Please check your connection.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }
}
