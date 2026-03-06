import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class InterviewHubScreen extends StatelessWidget {
  const InterviewHubScreen({super.key});

  static const List<_InterviewCard> _cards = [
    _InterviewCard(
      icon: Icons.record_voice_over_rounded,
      title: 'Mock Interview',
      subtitle: 'AI-powered interview simulation with real-time feedback',
      gradient: AppColors.primaryGradient,
      route: AppConstants.routeMockInterview,
      badge: 'Most Popular',
    ),
    _InterviewCard(
      icon: Icons.spellcheck_rounded,
      title: 'English Practice',
      subtitle: 'Improve grammar and professional communication',
      gradient: AppColors.tealGradient,
      route: AppConstants.routeEnglishPractice,
      badge: null,
    ),
    _InterviewCard(
      icon: Icons.code_rounded,
      title: 'Coding Preparation',
      subtitle: 'Practice 500+ real company questions with live code execution',
      gradient: AppColors.purpleGradient,
      route: AppConstants.routeCodingPrep,
      badge: '35 Companies',
    ),
    _InterviewCard(
      icon: Icons.calculate_rounded,
      title: 'Aptitude Test',
      subtitle: 'Quantitative, logical and verbal reasoning practice',
      gradient: LinearGradient(colors: [Color(0xFFf77f00), Color(0xFFf4a261)]),
      route: AppConstants.routeAptitude,
      badge: null,
    ),
    _InterviewCard(
      icon: Icons.assignment_rounded,
      title: 'Mock Test',
      subtitle: 'Full domain mock exams — DSA, CS Fundamentals, Frontend, ML',
      gradient: LinearGradient(colors: [Color(0xFF2ec4b6), Color(0xFF3a86ff)]),
      route: AppConstants.routeMockTest,
      badge: '6 Domains',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Interview Prep 🎤',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Practice until you are interview-ready',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _buildStatsRow(),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: _cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) =>
                      _InterviewCardWidget(card: _cards[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatBox(
            value: '8', label: 'Sessions', gradient: AppColors.primaryGradient),
        const SizedBox(width: 12),
        _StatBox(
            value: '76%', label: 'Avg Score', gradient: AppColors.tealGradient),
        const SizedBox(width: 12),
        _StatBox(
            value: '3h',
            label: 'Practiced',
            gradient: AppColors.purpleGradient),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final LinearGradient gradient;
  const _StatBox(
      {required this.value, required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterviewCardWidget extends StatelessWidget {
  final _InterviewCard card;
  const _InterviewCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    final isComingSoon = card.route == null;
    return GestureDetector(
      onTap: isComingSoon
          ? null
          : () =>
              context.go('/${AppConstants.routeInterviewHub}/${card.route}'),
      child: Opacity(
        opacity: isComingSoon ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: card.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(card.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          card.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (card.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isComingSoon
                                  ? AppColors.surfaceVariant
                                  : AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              card.badge!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isComingSoon
                                    ? AppColors.textHint
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.subtitle,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              if (!isComingSoon)
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterviewCard {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final String? route;
  final String? badge;
  const _InterviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.route,
    required this.badge,
  });
}
