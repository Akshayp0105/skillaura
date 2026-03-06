import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/coding_service.dart';

class AptitudeScreen extends StatefulWidget {
  const AptitudeScreen({super.key});

  @override
  State<AptitudeScreen> createState() => _AptitudeScreenState();
}

class _AptitudeScreenState extends State<AptitudeScreen> {
  final _service = CodingService();
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  static const _gradients = [
    AppColors.primaryGradient,
    AppColors.tealGradient,
    AppColors.purpleGradient,
    LinearGradient(colors: [Color(0xFFf77f00), Color(0xFFf4a261)]),
  ];

  static const _icons = [
    Icons.calculate_rounded,
    Icons.psychology_rounded,
    Icons.spellcheck_rounded,
    Icons.bar_chart_rounded,
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await _service.getAptitudeCategories();
    if (mounted) setState(() { _categories = data; _loading = false; });
  }

  @override
  void dispose() { _service.dispose(); super.dispose(); }

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
                Text('Aptitude Test', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text('Choose a category to start', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          // Info banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('15 questions per test • 15 minutes • Explanations provided', style: TextStyle(color: Colors.white, fontSize: 12))),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) => _CategoryCard(
                      category: _categories[i],
                      gradient: _gradients[i % _gradients.length],
                      icon: _icons[i % _icons.length],
                      onStart: () => context.go(
                        '/${AppConstants.routeInterviewHub}/${AppConstants.routeAptitude}/${AppConstants.routeAptitudeTest}',
                        extra: {'categoryId': _categories[i]['id'], 'categoryName': _categories[i]['name']},
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final LinearGradient gradient;
  final IconData icon;
  final VoidCallback onStart;
  const _CategoryCard({required this.category, required this.gradient, required this.icon, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.white, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(category['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.quiz_outlined, size: 12, color: AppColors.textHint),
            const SizedBox(width: 3),
            Text('${category['questions']} questions', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 10),
            const Icon(Icons.timer_outlined, size: 12, color: AppColors.textHint),
            const SizedBox(width: 3),
            Text('~${category['avg_time']} min', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ])),
        GestureDetector(
          onTap: onStart,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)),
            child: const Text('Start', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}
