import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/coding_service.dart';

class AptitudeTestScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  const AptitudeTestScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  State<AptitudeTestScreen> createState() => _AptitudeTestScreenState();
}

class _AptitudeTestScreenState extends State<AptitudeTestScreen> {
  final _service = CodingService();
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  int _current = 0;
  final Map<int, int> _selected = {};
  bool _submitted = false;

  // Timer (15 min)
  int _secondsLeft = 15 * 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getAptitudeQuestions(widget.categoryId, count: 15);
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

  void _submit() {
    _timer?.cancel();
    setState(() => _submitted = true);
  }

  int get _score {
    int s = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selected[i] == (_questions[i]['answer'] as int)) s++;
    }
    return s;
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
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
    final timerColor = _secondsLeft < 120 ? AppColors.error : AppColors.success;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.categoryName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
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
          // Progress bar
          LinearProgressIndicator(
            value: (_current + 1) / _questions.length,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
          ),
          // Question counter
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(children: [
              Text('Question ${_current + 1} of ${_questions.length}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
              const Spacer(),
              Text('${_selected.length} answered', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
                  child: Text(q['question'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.55)),
                ),
                const SizedBox(height: 16),
                ...List.generate(opts.length, (i) {
                  final sel = _selected[_current] == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selected[_current] = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary.withValues(alpha: 0.12) : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? AppColors.primary : Colors.white.withValues(alpha: 0.07), width: sel ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel ? AppColors.primary : Colors.transparent,
                            border: Border.all(color: sel ? AppColors.primary : AppColors.textHint),
                          ),
                          child: sel ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(opts[i], style: TextStyle(color: sel ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 14))),
                      ]),
                    ),
                  );
                }),
              ]),
            ),
          ),
          // Nav
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              if (_current > 0)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _current--),
                    child: Container(height: 48, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textPrimary),
                        SizedBox(width: 6),
                        Text('Previous', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      ])),
                    ),
                  ),
                ),
              if (_current > 0) const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _current < _questions.length - 1
                      ? () => setState(() => _current++)
                      : _submit,
                  child: Container(height: 48, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_current < _questions.length - 1 ? 'Next' : 'Submit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Icon(_current < _questions.length - 1 ? Icons.arrow_forward_rounded : Icons.upload_rounded, size: 16, color: Colors.white),
                    ])),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final score = _score;
    final total = _questions.length;
    final pct = (score / total * 100).round();
    final pass = pct >= 60;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary)),
              const SizedBox(width: 12),
              Text('Results — ${widget.categoryName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ]),
          ),
          // Score card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: pass ? AppColors.primaryGradient : const LinearGradient(colors: [Color(0xFFc0392b), Color(0xFFe74c3c)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                Icon(pass ? Icons.emoji_events_rounded : Icons.refresh_rounded, size: 40, color: Colors.white),
                const SizedBox(height: 8),
                Text('$pct%', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('$score out of $total correct', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(pass ? '✅ Passed!' : '❌ Try again!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
            ),
          ),
          // Detailed review
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
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: correct ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: correct ? AppColors.success : AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Q${i+1}: ${q2['question']}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 8),
                    Text('✅ Correct: ${opts2[ans]}', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                    if (!correct && sel2 != null)
                      Text('❌ Your answer: ${opts2[sel2]}', style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    if (sel2 == null)
                      const Text('⚠️ Not answered', style: TextStyle(color: AppColors.warning, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(q2['explanation'] ?? '', style: const TextStyle(color: AppColors.textHint, fontSize: 11, height: 1.4)),
                  ]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(height: 48, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Back to Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
            ),
          ),
        ]),
      ),
    );
  }
}
