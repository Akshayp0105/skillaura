import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/coding_service.dart';
import '../../../services/user_service.dart';

class MockTestExamScreen extends StatefulWidget {
  final String domainId;
  final String domainName;
  final int durationMinutes;
  const MockTestExamScreen({
    super.key,
    required this.domainId,
    required this.domainName,
    required this.durationMinutes,
  });

  @override
  State<MockTestExamScreen> createState() => _MockTestExamScreenState();
}

class _MockTestExamScreenState extends State<MockTestExamScreen> {
  final _service = CodingService();
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  int _current = 0;
  final Map<int, int> _selected = {};
  bool _submitted = false;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationMinutes * 60;
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getMockQuestions(widget.domainId);
    if (mounted) {
      setState(() { _questions = data; _loading = false; });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        if (mounted && !_submitted) _submit();
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  void _submit() async {
    _timer?.cancel();
    setState(() => _submitted = true);

    // Save stats
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final elapsedSeconds = (widget.durationMinutes * 60) - _secondsLeft;
      final totalQuestions = _questions.length;
      final finalScore = totalQuestions > 0 ? (_score / totalQuestions) * 100 : 0.0;
      await UserService().updateInterviewStats(
        uid: uid,
        additionalTimeSeconds: elapsedSeconds,
        sessionScore: finalScore,
        isNewSession: true,
      );
    }
  }

  int get _score {
    int s = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selected[i] == (_questions[i]['answer'] as int)) s++;
    }
    return s;
  }

  Map<String, List<Map<String, dynamic>>> get _bySection {
    final m = <String, List<Map<String, dynamic>>>{};
    for (int i = 0; i < _questions.length; i++) {
      final sec = _questions[i]['section'] ?? 'General';
      m.putIfAbsent(sec, () => []);
      m[sec]!.add({..._questions[i], '_index': i});
    }
    return m;
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60; final s = secs % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  @override
  void dispose() { _timer?.cancel(); _service.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    if (_submitted) return _buildResults(context);

    final q = _questions[_current];
    final opts = List<String>.from(q['options'] ?? []);
    final timerColor = _secondsLeft < 300 ? AppColors.error : (_secondsLeft < 600 ? AppColors.warning : AppColors.success);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)))),
            child: Row(children: [
              GestureDetector(onTap: () => _confirmQuit(context), child: const Icon(Icons.close_rounded, color: AppColors.textHint)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.domainName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Question ${_current + 1}/${_questions.length}  •  ${_selected.length} answered', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: timerColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.timer_rounded, size: 14, color: timerColor),
                  const SizedBox(width: 4),
                  Text(_formatTime(_secondsLeft), style: TextStyle(color: timerColor, fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
          // Progress
          LinearProgressIndicator(
            value: (_current + 1) / _questions.length,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
          ),
          // Section badge
          if ((q['section'] ?? '').isNotEmpty) Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(q['section'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          // Question + options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
                  child: Text(q['question'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.5)),
                ),
                const SizedBox(height: 16),
                ...List.generate(opts.length, (i) {
                  final sel = _selected[_current] == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selected[_current] = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary.withValues(alpha: 0.10) : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? AppColors.primary : Colors.white.withValues(alpha: 0.07), width: sel ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? AppColors.primary : Colors.transparent, border: Border.all(color: sel ? AppColors.primary : AppColors.textHint)),
                          child: sel ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null),
                        const SizedBox(width: 12),
                        Expanded(child: Text(opts[i], style: TextStyle(color: sel ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 14))),
                      ]),
                    ),
                  );
                }),
                // Question navigator
                const SizedBox(height: 16),
                Wrap(spacing: 6, runSpacing: 6, children: List.generate(_questions.length, (i) {
                  final done = _selected.containsKey(i);
                  return GestureDetector(
                    onTap: () => setState(() => _current = i),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: i == _current ? AppColors.primary : (done ? AppColors.success.withValues(alpha: 0.2) : AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: i == _current ? AppColors.primary : (done ? AppColors.success.withValues(alpha: 0.4) : Colors.transparent)),
                      ),
                      child: Center(child: Text('${i+1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: i == _current ? Colors.white : (done ? AppColors.success : AppColors.textHint)))),
                    ),
                  );
                })),
              ]),
            ),
          ),
          // Nav
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              if (_current > 0) ...[
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _current--),
                  child: Container(height: 48, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textPrimary), SizedBox(width: 6), Text('Prev', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))]))),
                )),
                const SizedBox(width: 10),
              ],
              Expanded(child: GestureDetector(
                onTap: _current < _questions.length - 1 ? () => setState(() => _current++) : _submit,
                child: Container(height: 48, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(_current < _questions.length - 1 ? 'Next →' : '🎯 Submit Exam', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  void _confirmQuit(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('End Exam?', style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('Progress will be lost.', style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () { Navigator.pop(ctx); context.pop(); }, child: const Text('Exit', style: TextStyle(color: AppColors.error))),
      ],
    ));
  }

  Widget _buildResults(BuildContext context) {
    final score = _score;
    final total = _questions.length;
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final pass = pct >= 60;
    final bySection = _bySection;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary)),
              const SizedBox(width: 12),
              Text('${widget.domainName} — Results', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: pass ? AppColors.primaryGradient : const LinearGradient(colors: [Color(0xFFc0392b), Color(0xFFe74c3c)]), borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Icon(pass ? Icons.emoji_events_rounded : Icons.refresh_rounded, size: 36, color: Colors.white),
                const SizedBox(height: 6),
                Text('$pct%', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('$score/$total correct', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(pass ? '✅ Passed!' : '❌ Needs Improvement', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          // Section breakdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: bySection.entries.map((e) {
              final sCorrect = e.value.where((q) => _selected[q['_index'] as int] == (q['answer'] as int)).length;
              final sTotal = e.value.length;
              final sPct = (sCorrect / sTotal * 100).round();
              return Expanded(child: Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('$sPct%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: sPct >= 60 ? AppColors.success : AppColors.error)),
                  const SizedBox(height: 2),
                  Text(e.key.split(' ').first, style: const TextStyle(fontSize: 9, color: AppColors.textHint), textAlign: TextAlign.center),
                ]),
              ));
            }).toList()),
          ),
          const SizedBox(height: 12),
          // Review list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _questions.length,
              itemBuilder: (_, i) {
                final q2 = _questions[i];
                final opts2 = List<String>.from(q2['options'] ?? []);
                final ans = q2['answer'] as int;
                final sel2 = _selected[i];
                final correct = sel2 == ans;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: correct ? AppColors.success.withValues(alpha: 0.25) : AppColors.error.withValues(alpha: 0.25))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 14, color: correct ? AppColors.success : AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Q${i+1}: ${q2['question']}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 6),
                    Text('✅ ${opts2[ans]}', style: const TextStyle(color: AppColors.success, fontSize: 11)),
                    if (!correct && sel2 != null) Text('❌ ${opts2[sel2]}', style: const TextStyle(color: AppColors.error, fontSize: 11)),
                    if (sel2 == null) const Text('⚠️ Skipped', style: TextStyle(color: AppColors.warning, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(q2['explanation'] ?? '', style: const TextStyle(color: AppColors.textHint, fontSize: 10, height: 1.4)),
                  ]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(height: 48, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Back to Domains', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)))),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}
