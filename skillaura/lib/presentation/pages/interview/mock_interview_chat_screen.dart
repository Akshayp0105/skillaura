import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/chat_message.dart';
import 'package:uuid/uuid.dart';

const String _kBackendUrl = 'http://localhost:8000';

class MockInterviewChatScreen extends StatefulWidget {
  const MockInterviewChatScreen({super.key});

  @override
  State<MockInterviewChatScreen> createState() => _MockInterviewChatScreenState();
}

class _MockInterviewChatScreenState extends State<MockInterviewChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _sessionId;
  List<Map<String, String>> _history = [];
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startNewSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startNewSession() {
    setState(() {
      _sessionId = _uuid.v4();
      _history = [];
      _messages = [
        ChatMessage(
          id: _uuid.v4(),
          content: "Hi! I'm your AI Mock Interviewer 🤖\n\nTo get started, please tell me the company and role you are interviewing for (e.g., 'Google Frontend Developer').",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    });
  }

  Future<void> _loadSession(String sessionId) async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mock_interviews')
          .doc(sessionId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final List<dynamic> rawHistory = data['history'] ?? [];
        
        List<Map<String, String>> newHistory = [];
        List<ChatMessage> newMessages = [];
        
        for (var msg in rawHistory) {
          final role = msg['role'] as String;
          final content = msg['content'] as String;
          newHistory.add({'role': role, 'content': content});
          newMessages.add(ChatMessage(
            id: _uuid.v4(),
            content: content,
            isUser: role == 'user',
            timestamp: DateTime.now(),
          ));
        }

        setState(() {
          _sessionId = sessionId;
          _history = newHistory;
          _messages = newMessages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Error loading chat session');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSessionToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _history.isEmpty) return;
    
    try {
      final title = _history.firstWhere((m) => m['role'] == 'user', orElse: () => {'content': 'New Interview'})['content'];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mock_interviews')
          .doc(_sessionId)
          .set({
        'updatedAt': FieldValue.serverTimestamp(),
        'history': _history,
        'title': title != null && title.length > 30 ? '${title.substring(0, 30)}...' : title,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save session: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    _history.add({'role': 'user', 'content': text});
    await _saveSessionToFirestore();

    try {
      final reply = await _callBackendChat(_history);

      _history.add({'role': 'assistant', 'content': reply});
      await _saveSessionToFirestore();

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            id: _uuid.v4(),
            content: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        _showError(e.toString());
      }
    }
  }

  Future<String> _callBackendChat(List<Map<String, String>> history) async {
    final response = await http
        .post(
          Uri.parse('$_kBackendUrl/mock-interview'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'messages': history}),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'].toString().trim();
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Backend error ${response.statusCode}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.record_voice_over_rounded, size: 16, color: Colors.white),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mock Interview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text('AI Interviewer', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textPrimary),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            tooltip: 'Chat History',
          ),
        ],
      ),
      endDrawer: _buildHistoryDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return _TypingIndicator();
                      }
                      return _ChatBubble(message: _messages[index]);
                    },
                  ),
                ),
                _buildInput(),
              ],
            ),
    );
  }

  Widget _buildHistoryDrawer() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Interviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    onPressed: () {
                      Navigator.pop(context);
                      _startNewSession();
                    },
                    tooltip: 'New Interview',
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.surfaceVariant),
            if (uid == null)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Login to save and view past interviews.', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('mock_interviews')
                      .orderBy('updatedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No recent interviews.', style: TextStyle(color: AppColors.textSecondary)),
                      );
                    }
                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Interview Session';
                        final isSelected = doc.id == _sessionId;
                        return ListTile(
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isSelected ? AppColors.primary : Colors.white)),
                          leading: const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.textSecondary),
                          tileColor: isSelected ? AppColors.surfaceVariant : null,
                          onTap: () {
                            Navigator.pop(context);
                            _loadSession(doc.id);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Type your answer...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.primaryGradient : null,
          color: isUser ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            SizedBox(width: 4),
            _Dot(delay: 150),
            SizedBox(width: 4),
            _Dot(delay: 300),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
