import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/coding_service.dart';

class CompanyQuestionsScreen extends StatefulWidget {
  final String companyId;
  final String companyName;
  const CompanyQuestionsScreen({super.key, required this.companyId, required this.companyName});

  @override
  State<CompanyQuestionsScreen> createState() => _CompanyQuestionsScreenState();
}

class _CompanyQuestionsScreenState extends State<CompanyQuestionsScreen> {
  final _service = CodingService();
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  String _selectedDiff = 'All';
  bool _loading = true;

  static const _diffs = ['All', 'Easy', 'Medium', 'Hard'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await _service.getQuestions(widget.companyId);
    if (mounted) setState(() { _all = data; _filtered = data; _loading = false; });
  }

  void _applyFilter(String diff) {
    setState(() {
      _selectedDiff = diff;
      _filtered = diff == 'All' ? _all : _all.where((q) => q['difficulty'] == diff).toList();
    });
  }

  @override
  void dispose() { _service.dispose(); super.dispose(); }

  Color _diffColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy': return AppColors.success;
      case 'medium': return AppColors.warning;
      default: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context),
          _buildFilters(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(children: [
              Text('${_filtered.length} problems', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? const Center(child: Text('No questions found', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _QuestionTile(
                          number: i + 1,
                          question: _filtered[i],
                          diffColor: _diffColor(_filtered[i]['difficulty'] ?? ''),
                          onTap: () => context.go(
                            '/${AppConstants.routeInterviewHub}/${AppConstants.routeCodingPrep}/${AppConstants.routeCompanyQuestions}/${AppConstants.routeCodingIDE}',
                            extra: {'questionId': _filtered[i]['id'], 'questionTitle': _filtered[i]['title']},
                          ),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const Text('Tap a problem to start coding', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 34,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _diffs.length,
          itemBuilder: (_, i) {
            final d = _diffs[i];
            final sel = _selectedDiff == d;
            return GestureDetector(
              onTap: () => _applyFilter(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.purpleGradient : null,
                  color: sel ? null : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(d, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, color: sel ? Colors.white : AppColors.textSecondary))),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final int number;
  final Map<String, dynamic> question;
  final Color diffColor;
  final VoidCallback onTap;
  const _QuestionTile({required this.number, required this.question, required this.diffColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final freq = (question['frequency'] ?? 0) as int;
    final acc  = (question['acceptance'] ?? 0) as int;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(children: [
          SizedBox(width: 28, child: Text('$number', style: const TextStyle(color: AppColors.textHint, fontSize: 13))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(question['title'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.layers_outlined, size: 12, color: AppColors.textHint),
              const SizedBox(width: 3),
              Text(question['topic'] ?? '', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
              const SizedBox(width: 10),
              const Icon(Icons.trending_up_rounded, size: 12, color: AppColors.textHint),
              const SizedBox(width: 3),
              Text('$acc% accepted', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(question['difficulty'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: diffColor)),
            ),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.whatshot_rounded, size: 11, color: AppColors.warning),
              Text('$freq%', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            ]),
          ]),
        ]),
      ),
    );
  }
}
