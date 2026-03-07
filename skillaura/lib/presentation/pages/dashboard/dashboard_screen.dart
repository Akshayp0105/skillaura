import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/job.dart';
import '../../../domain/entities/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/daily_task_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserEntity? _user;
  final AuthService _authService = AuthService();
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final user = await _authService.userService.getUser(currentUser.uid);
      final streakData = await DailyTaskService.getStreak(currentUser.uid);
      if (mounted) {
        setState(() {
          _user = user;
          _streak = streakData['current'] ?? 0;
        });
      }
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning! 🌅';
    if (h < 18) return 'Good Afternoon! ☀️';
    return 'Good Evening! 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final user = _user ?? MockData.currentUser;
    final displayName = _user?.fullName ?? user.fullName;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, displayName),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ResumeScoreCard(score: user.resumeScore),
                const SizedBox(height: 24),
                _DailyTasksSection(user: user, onStreakUpdated: (s) {
                  if (mounted) setState(() => _streak = s);
                }),
                const SizedBox(height: 24),
                _InternshipFeedSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, String name) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: AppColors.background,
      expandedHeight: 0,
      flexibleSpace: const FlexibleSpaceBar(
        background: ColoredBox(color: AppColors.background),
      ),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_greeting(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const Spacer(),
          // 🔥 Streak Badge
          if (_streak > 0)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFff6b35), Color(0xFFff9a3c)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFFff6b35).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('$_streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ]),
            ),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

// ── Resume Score Card ────────────────────────────────────────────────────────
class _ResumeScoreCard extends StatelessWidget {
  final int score;
  const _ResumeScoreCard({required this.score});

  Color get _scoreColor {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1B2E), Color(0xFF0F1020)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        CircularPercentIndicator(
          radius: 58, lineWidth: 9, percent: score / 100,
          center: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$score', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _scoreColor)),
            const Text('ATS', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          ]),
          progressColor: _scoreColor,
          backgroundColor: Colors.white.withValues(alpha: 0.07),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true, animationDuration: 1200,
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Resume Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Your resume is Good. Add more project details and quantify achievements.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
            child: const Text('✨ Improve Score', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ])),
      ]),
    );
  }
}

// ── Daily Tasks Section ──────────────────────────────────────────────────────
class _DailyTasksSection extends StatefulWidget {
  final UserEntity user;
  final ValueChanged<int> onStreakUpdated;
  const _DailyTasksSection({required this.user, required this.onStreakUpdated});

  @override
  State<_DailyTasksSection> createState() => _DailyTasksSectionState();
}

class _DailyTasksSectionState extends State<_DailyTasksSection> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (_uid == null) { setState(() => _loading = false); return; }
    final tasks = await DailyTaskService.getTodayTasks(
      uid: _uid!,
      skills: widget.user.skills,
      resumeScore: widget.user.resumeScore,
    );
    if (mounted) setState(() { _tasks = tasks; _loading = false; });
  }

  Future<void> _toggleTask(int index, bool value) async {
    if (_uid == null) return;
    final task = _tasks[index];
    final taskId = task['id'] as String;

    setState(() { _tasks[index] = {...task, 'done': value}; });

    if (value) {
      final allDone = await DailyTaskService.markTaskDone(uid: _uid!, taskId: taskId, allTasks: _tasks);
      if (allDone) {
        final s = await DailyTaskService.getStreak(_uid!);
        widget.onStreakUpdated(s['current'] ?? 0);
        if (mounted) _showStreakToast(s['current'] ?? 0);
      }
    } else {
      await DailyTaskService.unmarkTask(uid: _uid!, taskId: taskId, allTasks: _tasks);
    }
  }

  void _showStreakToast(int streak) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('🔥', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text('Amazing! $streak-day streak! All daily tasks done! 🎉',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: const Color(0xFFff6b35),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((t) => t['done'] == true).length;
    final total = _tasks.isEmpty ? 1 : _tasks.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Daily Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        _loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary))
            : Text('$completedCount/${_tasks.length} done', style: const TextStyle(color: AppColors.secondary, fontSize: 13)),
      ]),
      const SizedBox(height: 4),
      if (!_loading && _tasks.isNotEmpty) ...[
        const SizedBox(height: 4),
        _DifficultyBadge(difficulty: (_tasks.first['difficulty'] ?? 'Easy') as String),
      ],
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: completedCount / total,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
          minHeight: 5,
        ),
      ),
      const SizedBox(height: 14),
      if (_loading)
        const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
      else
        ..._tasks.asMap().entries.map((entry) {
          final i = entry.key;
          final task = entry.value;
          return _TaskTile(
            task: task,
            onChanged: (val) => _toggleTask(i, val!),
            onTap: () => _navigateTask(context, task),
          );
        }),
    ]);
  }

  void _navigateTask(BuildContext context, Map<String, dynamic> task) {
    final route = task['route'] as String? ?? '';
    if (route.isEmpty) return;
    context.go('/$route');
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = difficulty == 'Easy' ? AppColors.success : difficulty == 'Medium' ? AppColors.warning : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.trending_up_rounded, size: 12, color: color),
        const SizedBox(width: 4),
        Text("Today's level: $difficulty", style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Map<String, dynamic> task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTap;
  const _TaskTile({required this.task, required this.onChanged, required this.onTap});

  IconData _icon(String type) {
    switch (type) {
      case 'coding': return Icons.code_rounded;
      case 'aptitude': return Icons.calculate_rounded;
      case 'english': return Icons.spellcheck_rounded;
      case 'interview': return Icons.record_voice_over_rounded;
      case 'jobs': return Icons.work_outline_rounded;
      case 'resume': return Icons.description_outlined;
      case 'mocktest': return Icons.assignment_rounded;
      default: return Icons.task_alt_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'coding': return AppColors.primary;
      case 'aptitude': return const Color(0xFFf77f00);
      case 'english': return AppColors.secondary;
      case 'interview': return AppColors.success;
      case 'jobs': return const Color(0xFF3a86ff);
      case 'resume': return AppColors.warning;
      case 'mocktest': return const Color(0xFF2ec4b6);
      default: return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = task['done'] == true;
    final type = task['type'] as String? ?? 'general';
    final color = _typeColor(type);

    return GestureDetector(
      onTap: done ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done ? AppColors.secondary.withValues(alpha: 0.3) : color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(children: [
          // Type icon
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: done ? AppColors.success.withValues(alpha: 0.12) : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(done ? Icons.check_circle_rounded : _icon(type),
                size: 18, color: done ? AppColors.success : color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              task['title'] as String? ?? '',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: done ? AppColors.textHint : AppColors.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
            Text(task['subtitle'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ])),
          const SizedBox(width: 8),
          Checkbox(
            value: done,
            onChanged: onChanged,
            activeColor: AppColors.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: AppColors.textHint),
          ),
        ]),
      ),
    );
  }
}

// ── Internship Feed Section ──────────────────────────────────────────────────
class _InternshipFeedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final jobs = MockData.jobs.take(4).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Recommended for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        GestureDetector(
          onTap: () => context.go('/${AppConstants.routeJobs}'),
          child: const Text('See all', style: TextStyle(color: AppColors.primary, fontSize: 13)),
        ),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => _FeaturedJobCard(job: jobs[index]),
        ),
      ),
    ]);
  }
}

class _FeaturedJobCard extends StatelessWidget {
  final Job job;
  const _FeaturedJobCard({required this.job});

  Color _matchColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/${AppConstants.routeJobs}/${AppConstants.routeJobDetail}', extra: job),
      child: Container(
        width: 220, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _CompanyLogo(letter: job.logo),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _matchColor(job.matchScore).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${job.matchScore}% match',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _matchColor(job.matchScore))),
            ),
          ]),
          const SizedBox(height: 14),
          Text(job.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3)),
          const SizedBox(height: 4),
          Text(job.company, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
            const SizedBox(width: 3),
            Text(job.location, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const Spacer(),
            Text(job.salary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary)),
          ]),
        ]),
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final String letter;
  const _CompanyLogo({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(gradient: AppColors.purpleGradient, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
    );
  }
}
