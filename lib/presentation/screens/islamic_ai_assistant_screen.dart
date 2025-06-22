import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../services/islamic_ai_service.dart';
import '../providers/enhanced_theme_provider.dart';
import '../providers/chat_history_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class IslamicAIAssistantScreen extends StatefulWidget {
  const IslamicAIAssistantScreen({super.key});

  @override
  State<IslamicAIAssistantScreen> createState() =>
      _IslamicAIAssistantScreenState();
}

class _IslamicAIAssistantScreenState extends State<IslamicAIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  IslamicAIService? _aiService;

  @override
  void initState() {
    super.initState();

    // Initialize chat history provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider =
          Provider.of<ChatHistoryProvider>(context, listen: false);
      await chatProvider.initialize();
    });

    // Initialize AI service
    try {
      _aiService = IslamicAIService();
    } catch (e) {
      // Handle error if API key is not found
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showApiKeyErrorDialog();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _aiService == null) return;

    final userMessage = _messageController.text.trim();
    final chatProvider =
        Provider.of<ChatHistoryProvider>(context, listen: false);

    // Add user message
    chatProvider.addUserMessage(userMessage);
    _messageController.clear();
    _scrollToBottom();

    // Set loading state
    chatProvider.setLoading(true);

    try {
      final response = await _aiService!.askQuestion(userMessage);

      // Add assistant response
      chatProvider.addAssistantMessage(
        response.message,
        isError: false,
        shouldShowIftaLink: response.shouldRedirectToIfta,
      );

      chatProvider.setLoading(false);
      _scrollToBottom();

      if (response.shouldRedirectToIfta) {
        _showIftaRedirectDialog();
      }
    } catch (e) {
      chatProvider.addAssistantMessage(
        "I apologize, but I'm having trouble connecting to the service. Please try again later.",
        isError: true,
      );
      chatProvider.setLoading(false);
      _scrollToBottom();
    }
  }

  void _showIftaRedirectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consult Scholars'),
        content: const Text(
          'For more detailed guidance on this topic, would you like to visit the Egyptian Dar Al-Ifta website?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              IslamicAIService.openEgyptianIfta();
            },
            child: const Text('Visit Website'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Configuration Error'),
        content: const Text(
          'OpenAI API key not found. Please ensure you have:\n\n'
          '1. Created a .env file in the project root\n'
          '2. Added your OpenAI API key: OPENAI_API_KEY=your_key\n'
          '3. Restarted the app',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to clear all chat history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<ChatHistoryProvider>(context, listen: false)
                  .clearHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<EnhancedThemeProvider>(context);
    final isDarkTheme = themeProvider.isDarkTheme(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ChatHistoryProvider>(
      builder: (context, chatProvider, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              // Header with clear history button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Islamic Knowledge Assistant',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Ask about Quran, Hadith, and Islamic teachings',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (chatProvider.hasMessages)
                      IconButton(
                        onPressed: _showClearHistoryDialog,
                        icon: Icon(
                          Icons.delete_sweep_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        tooltip: 'Clear Chat History',
                      ),
                  ],
                ),
              ),

              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length +
                      (chatProvider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatProvider.messages.length &&
                        chatProvider.isLoading) {
                      return const _LoadingIndicator();
                    }

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _MessageBubble(
                            message: chatProvider.messages[index],
                            colorScheme: colorScheme,
                            isDarkTheme: isDarkTheme,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Input field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _aiService != null
                            ? _sendMessage()
                            : _showApiKeyErrorDialog(),
                        decoration: InputDecoration(
                          hintText: 'Ask your question...',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: chatProvider.isLoading
                            ? null
                            : (_aiService != null
                                ? _sendMessage
                                : _showApiKeyErrorDialog),
                        icon: Icon(
                          Icons.send_rounded,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme colorScheme;
  final bool isDarkTheme;

  const _MessageBubble({
    required this.message,
    required this.colorScheme,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colorScheme.primary
                    : message.isError
                        ? colorScheme.error.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? colorScheme.onPrimary
                      : message.isError
                          ? colorScheme.error
                          : colorScheme.onSurface,
                ),
              ),
            ),
            if (message.shouldShowIftaLink)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  onPressed: () => IslamicAIService.openEgyptianIfta(),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Visit Egyptian Dar Al-Ifta'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    textStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
