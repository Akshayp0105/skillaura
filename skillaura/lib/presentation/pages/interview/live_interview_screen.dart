import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/theme/app_theme.dart';

class LiveInterviewScreen extends StatefulWidget {
  final String role;
  final String company;

  const LiveInterviewScreen({
    super.key,
    required this.role,
    required this.company,
  });

  @override
  State<LiveInterviewScreen> createState() => _LiveInterviewScreenState();
}

class _LiveInterviewScreenState extends State<LiveInterviewScreen> {
  CameraController? _cameraController;
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  String _lastWords = "";
  String _aiResponse = "Initializing your AI interviewer...";
  bool _isSpeaking = false;
  
  List<Map<String, String>> _history = [];
  bool _isSessionEnded = false;
  bool _cameraError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize Camera
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras.first, ResolutionPreset.medium);
        await _cameraController!.initialize();
      } else {
        if (mounted) setState(() => _cameraError = true);
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
      if (mounted) setState(() => _cameraError = true);
    }

    try {
      // Initialize Speech
      await _speechToText.initialize(
        onError: (e) => debugPrint("Speech error: $e"),
        onStatus: (s) => debugPrint("Speech status: $s"),
      );
    } catch (e) {
      debugPrint("Speech init error: $e");
    }
    
    try {
      // Initialize TTS
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint("TTS init error: $e");
    }

    if (mounted) {
      setState(() {});
      // Start the interview
      _startInterview();
    }
  }

  Future<void> _startInterview() async {
    final initialPrompt = "Hi! I'm your AI Interviewer. I see you're applying for the ${widget.role} role at ${widget.company}. Let's begin. Can you tell me a bit about yourself and why you're interested in this position?";
    setState(() {
      _aiResponse = initialPrompt;
    });
    _speak(initialPrompt);
    _history.add({'role': 'assistant', 'content': initialPrompt});
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    try {
      await _flutterTts.speak(text);
      
      // Fallback for Web where completion handler might not fire
      Future.delayed(Duration(milliseconds: (text.length * 60) + 2000), () {
        if (_isSpeaking && mounted) {
           setState(() => _isSpeaking = false);
           _startListening();
        }
      });

      _flutterTts.setCompletionHandler(() {
        if (mounted && _isSpeaking) {
          setState(() => _isSpeaking = false);
          _startListening();
        }
      });
    } catch (e) {
      debugPrint("TTS speak error: $e");
      if (mounted) {
        setState(() => _isSpeaking = false);
        _startListening();
      }
    }
  }

  void _startListening() async {
    if (!_isListening && !_isSessionEnded) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
        },
      );
      setState(() => _isListening = true);
    }
  }

  void _finishSpeaking() {
    if (!_isListening) return;
    setState(() => _isListening = false);
    _speechToText.stop();
    
    String finalWords = _lastWords.isNotEmpty ? _lastWords : "(No speech detected)";
    _sendToAI(finalWords);
  }

  Future<void> _sendToAI(String text) async {
    _history.add({'role': 'user', 'content': text});
    
    setState(() {
      _aiResponse = "Thinking...";
      _lastWords = "";
    });

    String? base64Image;
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final image = await _cameraController!.takePicture();
        final bytes = await image.readAsBytes();
        base64Image = base64Encode(bytes);
      } catch (e) {
        debugPrint("Camera capture error: $e");
      }
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/mock-interview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': _history,
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'];
        _history.add({'role': 'assistant', 'content': reply});
        
        setState(() {
          _aiResponse = reply;
        });

        if (reply.toLowerCase().contains("score") || reply.toLowerCase().contains("thank you for your time")) {
          _isSessionEnded = true;
          _addGestureFeedback();
        }

        _speak(reply);
      }
    } catch (e) {
      setState(() => _aiResponse = "Error: Could not connect to AI.");
    }
  }

  void _addGestureFeedback() {
    // The backend now provides live gesture feedback, so we only need a closing remark here if desired.
    setState(() {
      _aiResponse += "\n\n[End of Interview Segment]";
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Live AI Interview"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (_cameraError)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off, color: Colors.white54, size: 50),
                        SizedBox(height: 10),
                        Text("Camera Unavailable / No Permissions", style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  )
                else if (_cameraController != null && _cameraController!.value.isInitialized)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                
                if (_isListening)
                  Positioned(
                    bottom: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _StatusIndicator(text: "Listening...", icon: Icons.mic, color: Colors.red),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _finishSpeaking,
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          label: const Text("Done Speaking", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isSpeaking)
                  const _StatusIndicator(text: "AI Speaking...", icon: Icons.volume_up, color: AppColors.primary),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AI INTERVIEWER",
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _aiResponse,
                      style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                    ),
                    if (_lastWords.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        "You: $_lastWords",
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontStyle: FontStyle.italic),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _StatusIndicator({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
