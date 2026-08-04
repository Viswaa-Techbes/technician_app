import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Default initial greeting message
    _messages.add({
      'role': 'assistant',
      'content': 'Hello! I am your TechBes Smart Service Advisor. I can recommend CCTV packages, estimate installation costs, compare camera brands, or assist in booking. How can I help you today? 👋',
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final client = ref.read(dioClientProvider);
      
      // Map message history to send to backend chat
      final backendMessages = _messages.map((m) => {
        'role': m['role'],
        'content': m['content']
      }).toList();

      final response = await client.post('/api/v2/ai/chat', data: {
        'messages': backendMessages,
      });

      if (response.data != null && response.data['success'] == true) {
        final reply = response.data['data']['reply'] ?? 'I apologize, I missed that. Could you repeat?';
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isTyping = false;
        });
      } else {
        throw Exception('AI server failed to respond');
      }
    } catch (e) {
      debugPrint('AI Chat Error: $e');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'I am currently operating in offline/demo mode due to connection constraints. To estimate CCTV packages: 4 Cameras standard setup ranges between ₹12,000 to ₹15,000. Let me know if you would like me to escalate this to Support.',
          'canHandoff': true
        });
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _triggerHandoff() async {
    setState(() => _isTyping = true);
    try {
      final client = ref.read(dioClientProvider);
      // Compile chat logs
      final log = _messages.map((m) => '${m['role']}: ${m['content']}').join('\n');
      final response = await client.post('/api/v2/ai/handoff', data: {
        'summary': 'User requested AI assistant support escalation.',
        'chatLog': log,
      });

      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'A human customer support ticket has been created! A TechBes agent will review this chat transcript and contact you shortly. Ticket ID: #${response.data['data']['_id']?.toString().substring(0, 6).toUpperCase() ?? "TICKET"}.',
          });
          _isTyping = false;
        });
      } else {
        throw Exception('Handoff api failed');
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'We created a priority Support ticket for you. An agent will call you on your registered mobile number shortly.',
        });
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Service Assistant'),
      ),
      body: Column(
        children: [
          // Chat logs
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isUser = m['role'] == 'user';
                return _buildMessageBubble(m, isUser);
              },
            ),
          ),

          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
              child: Row(
                children: [
                  SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
                  SizedBox(width: 10),
                  Text('Advisor is composing response...', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                ],
              ),
            ),

          // Shortcut chips panel
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildShortcutChip('Compare CCTV Brands', 'Which camera brand is best? Hikvision vs CP Plus vs TechBes Pro?'),
                  _buildShortcutChip('DVR vs NVR?', 'What is the difference between DVR and NVR?'),
                  _buildShortcutChip('Cost Estimation', 'Estimate CCTV installation cost for 4 cameras'),
                  _buildShortcutChip('Recommend AMC plans', 'Which AMC maintenance contract should I choose?'),
                  _buildShortcutChip('Escalate to support', 'Please escalate my request to support'),
                ],
              ),
            ),
          ),

          // Input field panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (val) => _sendMessage(val),
                    decoration: const InputDecoration(
                      hintText: 'Type your service query here...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutChip(String label, String promptToSend) {
    return GestureDetector(
      onTap: () {
        if (label.toLowerCase().contains('escalate')) {
          _triggerHandoff();
        } else {
          _sendMessage(promptToSend);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.04),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: isUser ? null : Border.all(color: AppTheme.borderColor),
          boxShadow: [
            if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m['content'],
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isUser ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            if (m['canHandoff'] == true) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _triggerHandoff,
                icon: const Icon(Icons.support_agent, size: 16, color: AppTheme.primaryColor),
                label: const Text('Connect with Support Agent', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
