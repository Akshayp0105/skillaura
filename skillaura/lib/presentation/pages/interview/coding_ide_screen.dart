import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/coding_service.dart';

class CodingIDEScreen extends StatefulWidget {
  final String questionId;
  final String questionTitle;
  const CodingIDEScreen({super.key, required this.questionId, required this.questionTitle});

  @override
  State<CodingIDEScreen> createState() => _CodingIDEScreenState();
}

class _CodingIDEScreenState extends State<CodingIDEScreen> {
  final _service = CodingService();
  final _codeController = TextEditingController();
  final _scrollController = ScrollController();

  Map<String, dynamic>? _question;
  String _selectedLang = 'python';
  bool _loadingQuestion = true;
  bool _running = false;
  bool _evaluating = false;
  Map<String, dynamic>? _runResult;
  Map<String, dynamic>? _evalResult;

  // Timer
  bool _timerRunning = false;
  int _seconds = 0;
  Timer? _timer;

  static const _langs = ['python', 'javascript', 'java'];

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final q = await _service.getQuestionDetail(widget.questionId);
    if (mounted) {
      setState(() {
        _question = q;
        _loadingQuestion = false;
        final starter = (q?['starter_code'] as Map?)?.cast<String, dynamic>() ?? {};
        _codeController.text = starter[_selectedLang] ?? '# Write your solution here\n';
      });
    }
  }

  void _onLangChanged(String lang) {
    final starter = (_question?['starter_code'] as Map?)?.cast<String, dynamic>() ?? {};
    setState(() {
      _selectedLang = lang;
      _codeController.text = starter[lang] ?? '// Write your solution here\n';
      _runResult = null;
      _evalResult = null;
    });
  }

  Future<void> _runCode() async {
    setState(() { _running = true; _runResult = null; _evalResult = null; });
    final tcs = List<Map<String, dynamic>>.from(_question?['test_cases'] ?? []);
    final result = await _service.runCode(
      code: _codeController.text,
      language: _selectedLang,
      testCases: tcs,
    );
    if (mounted) setState(() { _running = false; _runResult = result; });
    _scrollToBottom();
  }

  Future<void> _submitCode() async {
    setState(() { _evaluating = true; _runResult = null; });
    await _runCode();
    final eval = await _service.evaluateCode(
      code: _codeController.text,
      language: _selectedLang,
      questionId: widget.questionId,
    );
    if (mounted) setState(() { _evaluating = false; _evalResult = eval; });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      _timerRunning = !_timerRunning;
      if (_timerRunning) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _seconds++);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  void _quit(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Quit Problem?', style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('Your code will not be saved.', style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () { Navigator.pop(ctx); context.pop(); },
          child: const Text('Quit', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingQuestion) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(children: [
                _buildProblemPanel(),
                _buildEditorPanel(),
                if (_running || _evaluating) const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    SizedBox(width: 12),
                    Text('Running code...', style: TextStyle(color: AppColors.textSecondary)),
                  ]),
                ),
                if (_runResult != null) _buildRunResults(),
                if (_evalResult != null) _buildEvalResults(),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final diff = _question?['difficulty'] ?? '';
    final diffColor = diff == 'Easy' ? AppColors.success : diff == 'Medium' ? AppColors.warning : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(widget.questionTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(diff, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: diffColor)),
        ),
        const SizedBox(width: 10),
        // Timer
        GestureDetector(
          onTap: _toggleTimer,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: _timerRunning ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timer_rounded, size: 14, color: _timerRunning ? AppColors.primary : AppColors.textHint),
              const SizedBox(width: 4),
              Text(_formatTime(_seconds), style: TextStyle(fontSize: 12, color: _timerRunning ? AppColors.primary : AppColors.textHint, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        // Quit
        GestureDetector(
          onTap: () => _quit(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
          ),
        ),
      ]),
    );
  }

  Widget _buildProblemPanel() {
    if (_question == null) return const SizedBox.shrink();
    final examples = List<Map<String, dynamic>>.from(_question!['examples'] ?? []);
    final constraints = List<String>.from(_question!['constraints'] ?? []);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Problem', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 10),
        Text(_question!['description'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
        if (examples.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Examples', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          for (int i = 0; i < examples.length; i++) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Example ${i+1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                const SizedBox(height: 4),
                Text('Input: ${examples[i]['input'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace')),
                Text('Output: ${examples[i]['output'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace')),
                if ((examples[i]['explanation'] ?? '').isNotEmpty)
                  Text('Explanation: ${examples[i]['explanation']}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ]),
            ),
          ],
        ],
        if (constraints.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Constraints', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          for (final c in constraints) Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 13)),
              Expanded(child: Text(c, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace'))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildEditorPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(children: [
        // Editor toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
          ),
          child: Row(children: [
            const Icon(Icons.code_rounded, size: 14, color: AppColors.textHint),
            const SizedBox(width: 6),
            const Text('Code Editor', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600)),
            const Spacer(),
            // Language selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLang,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  icon: const Icon(Icons.expand_more_rounded, size: 14, color: AppColors.primary),
                  isDense: true,
                  items: _langs.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => v != null ? _onLangChanged(v) : null,
                ),
              ),
            ),
          ]),
        ),
        // Code input
        SizedBox(
          height: 300,
          child: TextField(
            controller: _codeController,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFFe2e8f0),
              height: 1.6,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: '// Write your solution here...',
              hintStyle: TextStyle(color: Color(0xFF4A5568), fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
        // Run / Submit buttons
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
          ),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _running ? null : _runCode,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(_running ? 'Running...' : 'Run Code', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ])),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _evaluating ? null : _submitCode,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.upload_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(_evaluating ? 'Checking...' : 'Submit', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ])),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRunResults() {
    final results = List<Map<String, dynamic>>.from(_runResult!['results'] ?? []);
    final passed = (_runResult!['passed'] ?? 0) as int;
    final total  = (_runResult!['total'] ?? 0) as int;
    final allPassed = _runResult!['all_passed'] == true;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allPassed ? AppColors.success.withValues(alpha: 0.08) : AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: allPassed ? AppColors.success.withValues(alpha: 0.25) : AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(allPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: allPassed ? AppColors.success : AppColors.error, size: 18),
          const SizedBox(width: 8),
          Text(allPassed ? 'All Test Cases Passed! 🎉' : '$passed/$total Test Cases Passed',
              style: TextStyle(color: allPassed ? AppColors.success : AppColors.error, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        if (results.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final r in results) _TestCaseRow(result: r),
        ],
      ]),
    );
  }

  Widget _buildEvalResults() {
    if (_evalResult == null) return const SizedBox.shrink();
    final score = (_evalResult!['quality_score'] ?? 0) as int;
    final timeC = _evalResult!['time_complexity'] ?? 'N/A';
    final spaceC = _evalResult!['space_complexity'] ?? 'N/A';
    final suggestions = List<String>.from(_evalResult!['suggestions'] ?? []);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Code Analysis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(children: [
          _EvalBadge(label: 'Time', value: timeC, color: AppColors.warning),
          const SizedBox(width: 10),
          _EvalBadge(label: 'Space', value: spaceC, color: AppColors.primary),
          const SizedBox(width: 10),
          _EvalBadge(label: 'Score', value: '$score/100', color: score >= 70 ? AppColors.success : AppColors.error),
        ]),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final s in suggestions) Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Expanded(child: Text(s, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _TestCaseRow extends StatelessWidget {
  final Map<String, dynamic> result;
  const _TestCaseRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final passed = result['passed'] == true;
    final timeMs = result['time_ms'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: passed ? AppColors.success.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(passed ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
            size: 14, color: passed ? AppColors.success : AppColors.error),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Case ${result['case']}: ${passed ? 'Passed' : 'Failed'}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: passed ? AppColors.success : AppColors.error)),
          if (!passed) ...[
            Text('Expected: ${result['expected']}', style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontFamily: 'monospace')),
            Text('Got: ${result['actual']}', style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontFamily: 'monospace')),
          ],
          if ((result['error'] ?? '').isNotEmpty && !passed)
            Text('Error: ${result['error']}', style: const TextStyle(fontSize: 10, color: AppColors.error, fontFamily: 'monospace'), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        Text('${timeMs}ms', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      ]),
    );
  }
}

class _EvalBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _EvalBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      ]),
    );
  }
}
