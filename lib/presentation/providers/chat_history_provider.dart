import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final bool shouldShowIftaLink;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.shouldShowIftaLink = false,
  });

  // Convert to/from Map for Hive storage
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isError': isError,
      'shouldShowIftaLink': shouldShowIftaLink,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isError: json['isError'] as bool? ?? false,
      shouldShowIftaLink: json['shouldShowIftaLink'] as bool? ?? false,
    );
  }
}

class ChatHistoryProvider extends ChangeNotifier {
  static const String _boxName = 'chat_history';
  late Box _chatBox;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get hasMessages => _messages.isNotEmpty;

  Future<void> initialize() async {
    try {
      _chatBox = await Hive.openBox(_boxName);
      await _loadMessages();

      // Add welcome message if no messages exist
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }
    } catch (e) {
      // If there's an error, just add welcome message
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text:
          "Assalamu Alaikum! I'm your Islamic knowledge assistant. I can help you with questions about:\n\n"
          "• The Holy Quran and Tafsir\n"
          "• Hadith and Sunnah\n"
          "• Islamic jurisprudence (Fiqh)\n"
          "• Prayer and worship\n"
          "• Islamic history\n\n"
          "How may I assist you today?",
      isUser: false,
      timestamp: DateTime.now(),
    );

    _messages.add(welcomeMessage);
    notifyListeners();
  }

  Future<void> _loadMessages() async {
    try {
      final savedMessages = _chatBox.get('messages', defaultValue: <Map>[]);
      _messages.clear();

      for (final messageData in savedMessages) {
        if (messageData is Map) {
          try {
            final message =
                ChatMessage.fromJson(Map<String, dynamic>.from(messageData));
            _messages.add(message);
          } catch (e) {
            // Skip invalid message
            continue;
          }
        }
      }

      notifyListeners();
    } catch (e) {
      // If loading fails, start with empty list
      _messages.clear();
    }
  }

  Future<void> _saveMessages() async {
    try {
      final messagesList = _messages.map((msg) => msg.toJson()).toList();
      await _chatBox.put('messages', messagesList);
    } catch (e) {
      // Saving failed, but don't crash the app
      debugPrint('Failed to save chat history: $e');
    }
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
    _saveMessages(); // Save immediately when message is added
  }

  void addUserMessage(String text) {
    final message = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    addMessage(message);
  }

  void addAssistantMessage(String text,
      {bool isError = false, bool shouldShowIftaLink = false}) {
    final message = ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      isError: isError,
      shouldShowIftaLink: shouldShowIftaLink,
    );
    addMessage(message);
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _messages.clear();
    _addWelcomeMessage();
    await _saveMessages();
    notifyListeners();
  }

  Future<void> exportChatHistory() async {
    // This could be used for sharing chat history
    // Return formatted string of all messages
  }

  // Get messages count for statistics
  int get totalMessages => _messages.length;
  int get userMessagesCount => _messages.where((msg) => msg.isUser).length;
  int get assistantMessagesCount =>
      _messages.where((msg) => !msg.isUser).length;
}
