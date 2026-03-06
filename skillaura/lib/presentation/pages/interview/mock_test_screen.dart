import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/coding_service.dart';

class MockTestScreen extends StatefulWidget {
  const MockTestScreen({super.key});

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  final _service = CodingService();
  List<Map<String, dynamic>> _domains = [];
  bool _loading = true;

  static const _icons = [
    Icons.account_tree_rounded,
    Icons.computer_rounded,
    Icons.web_rounded,
    Icons.storage_rounded,
    Icons.architecture_rounded,
    Icons.psychology_rounded,
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await _service.getMockDomains();
    if (mounted) setState(() { _domains = data; _loading = false; });
  }

  @override
  void dispose() { _service.dispose(); super.dispose(); }

  Color _diffColor(String diff) {
    if (diff.contains('Easy')) return AppColors.success;
    if (diff.contains('Hard')) return AppColors.error;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 14),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Mock Test', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text('Full exam with score analysis', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _domains.length,
                    itemBuilder: (_, i) {
                      final d = _domains[i];
                      final duration = (d['duration'] ?? 60) as int;
                      final qCount = (d['questions'] ?? 30) as int;
                      final diff = d['difficulty'] ?? 'Medium';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(width: 46, height: 46,
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: Icon(_icons[i % _icons.length], color: AppColors.primary, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: _diffColor(diff).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                                child: Text(diff, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _diffColor(diff))),
                              ),
                            ])),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _InfoChip(icon: Icons.quiz_outlined, label: '$qCount Questions'),
                            const SizedBox(width: 8),
                            _InfoChip(icon: Icons.timer_outlined, label: '$duration min'),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.go(
                                '/interview/mock-test/mock-test-exam',
                                extra: {'domainId': d['id'], 'domainName': d['name'], 'duration': duration},
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                                child: const Text('Start Exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ),
                          ]),
                        ]),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}
