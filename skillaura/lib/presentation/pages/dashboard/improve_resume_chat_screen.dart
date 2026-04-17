import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../services/user_service.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

const String _kBackendUrl = 'https://skillaura.onrender.com';

class ImproveResumeChatScreen extends StatefulWidget {
  const ImproveResumeChatScreen({super.key});

  @override
  State<ImproveResumeChatScreen> createState() => _ImproveResumeChatScreenState();
}

class _ImproveResumeChatScreenState extends State<ImproveResumeChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  List<Map<String, String>> _history = [];
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  // Track generated links to render action buttons
  String? _pdfUrl;
  String? _docxUrl;

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

  Future<void> _startNewSession() async {
    setState(() {
      _history = [];
      _pdfUrl = null;
      _docxUrl = null;
      // Use a loading placeholder; real greeting comes from backend
      _messages = [];
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final profile = await UserService().getUser(uid);
        if (profile != null) {
          final skills = profile.skills.join(', ');
          final resumeScore = profile.resumeScore;
          // Pass profile context so backend can use it for "Rate Profile Resume" path
          final resumeContext =
              'System Context: The user\'s current known skills are: $skills. '
              'Their current ATS resume score is $resumeScore/100. '
              'Use this to provide improvement tips if they choose to rate their profile resume.';
          _history.add({'role': 'user', 'content': resumeContext});
          _history.add({'role': 'assistant', 'content': 'Understood. Profile context received.'});
        }
      } catch (e) {
        debugPrint('Could not fetch user profile for resume context: $e');
      }
    }

    // Trigger the backend to send the greeting (Rate vs Build options)
    setState(() {
      _isTyping = true;
    });
    await _callBackendForReply(isGreeting: true);
    setState(() {
      _isTyping = false;
    });
  }


  /// Calls the backend and adds response as a bot message.
  /// Used for the initial greeting (isGreeting: true) without a user message.
  Future<void> _callBackendForReply({bool isGreeting = false}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final response = await http
          .post(
            Uri.parse('$_kBackendUrl/improve-resume'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'uid': uid ?? '',
              'messages': _history,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'].toString().trim();
        _history.add({'role': 'assistant', 'content': reply});

        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              id: _uuid.v4(),
              content: reply,
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      // On greeting fetch failure, show a simple fallback welcome
      if (mounted && isGreeting) {
        setState(() {
          _messages.add(ChatMessage(
            id: _uuid.v4(),
            content:
                "Hello! 👋 I'm your **AI Resume Assistant**.\n\nReply **1** to rate your resume, or **2** to build a new one.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
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
      _pdfUrl = null;
      _docxUrl = null;
    });
    _scrollToBottom();

    _history.add({'role': 'user', 'content': text});

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final response = await http
          .post(
            Uri.parse('$_kBackendUrl/improve-resume'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'uid': uid ?? '',
              'messages': _history
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'].toString().trim();
        _history.add({'role': 'assistant', 'content': reply});
        
        // If the backend generated a resume, they will pass download links
        String? pdf = data['pdf_url'];
        String? docx = data['docx_url'];

        if (mounted) {
          setState(() {
            _isTyping = false;
            _messages.add(ChatMessage(
              id: _uuid.v4(),
              content: reply,
              isUser: false,
              timestamp: DateTime.now(),
            ));
            if (pdf != null && docx != null) {
              _pdfUrl = pdf;
              _docxUrl = docx;
            }
          });
          _scrollToBottom();
        }
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['detail'] ?? 'Backend error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        _showError(e.toString());
      }
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
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.description_rounded, size: 16, color: Colors.white),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Basic Resume Builder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text('AI Assistant', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
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
                
                final msg = _messages[index];
                final isLastMsg = index == _messages.length - 1;

                return Column(
                  children: [
                    _ChatBubble(message: msg),
                    if (isLastMsg && _pdfUrl != null && _docxUrl != null && !msg.isUser)
                      _buildDownloadActions()
                  ],
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildDownloadActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => _launchURL('$_kBackendUrl$_pdfUrl'),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
            label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _launchURL('$_kBackendUrl$_docxUrl'),
            icon: const Icon(Icons.description, color: Colors.white, size: 18),
            label: const Text('Download Word', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2b579a), // Word blue
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('Could not download file');
    }
  }

  Future<void> _pickAndAnalyzeFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      // Show uploading indicator
      setState(() {
        _isTyping = true;
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          content: '📎 ${file.name}',
          isUser: true,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();

      // Call backend to extract text + run ATS analysis
      final base64Content = base64Encode(bytes);
      final response = await http.post(
        Uri.parse('$_kBackendUrl/analyze-resume-base64'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': base64Content, 'file_name': file.name}),
      ).timeout(const Duration(seconds: 30));

      setState(() => _isTyping = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int atsScore = data['ats_score'] ?? 0;
        final List skills = data['skills'] ?? [];
        final List suggestions = data['suggestions'] ?? [];
        final String skillText = skills.take(12).join(', ').isNotEmpty
            ? skills.take(12).join(', ')
            : 'None detected';
        final String sugText = (suggestions as List).take(6)
            .map((s) => '• $s').join('\n');

        final String grade = atsScore >= 80 ? '🟢 Excellent' : atsScore >= 60 ? '🟡 Good' : '🔴 Needs Work';

        final analysisReply =
            '## 📊 Resume Analysis: ${file.name}\n\n'
            '**ATS Score: $atsScore/100** — $grade\n\n'
            '**Detected Skills (${skills.length}):**\n$skillText\n\n'
            '### 🔧 Improvement Suggestions:\n$sugText\n\n'
            '---\n*Type **build** to create an improved resume, or **menu** to return.*';

        // Add to history so chatbot knows we analyzed a resume
        _history.add({'role': 'user', 'content': '[User uploaded resume: ${file.name}]'});
        _history.add({'role': 'assistant', 'content': analysisReply});

        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              id: _uuid.v4(),
              content: analysisReply,
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();
        }
      } else {
        _showError('Could not analyze file. Try a text-based PDF or DOCX.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        _showError('Error reading file: ${e.toString().split(":").last.trim()}');
      }
    }
  }


  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
            tooltip: 'Upload PDF/DOCX resume for analysis',
            onPressed: _pickAndAnalyzeFile,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Type or upload your resume...',
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
