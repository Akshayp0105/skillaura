import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job.dart';
import '../../../domain/entities/user.dart';
import '../../../services/user_service.dart';
import '../../../services/job_service.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _userService = UserService();
  final _jobService = JobService();

  bool _saved = false;
  UserEntity? _currentUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final user = await _userService.getUser(firebaseUser.uid);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _loadingUser = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  @override
  void dispose() {
    _jobService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    key: ValueKey(_saved),
                    color: _saved ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                onPressed: () => setState(() => _saved = !_saved),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJobHeader(job),
                  const SizedBox(height: 20),
                  _buildInfoRow(job),
                  const SizedBox(height: 24),
                  _buildMatchSection(job),
                  const SizedBox(height: 24),
                  _buildSection('About the Role', job.fullDescription.isNotEmpty
                      ? job.fullDescription
                      : job.description),
                  const SizedBox(height: 20),
                  _buildSkillsSection(job),
                  const SizedBox(height: 32),
                  _buildApplySection(job),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobHeader(Job job) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              job.logo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                job.company,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              if (job.category.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    job.category,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(Job job) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _InfoChip(icon: Icons.location_on_outlined, label: job.location.isNotEmpty ? job.location : 'Location N/A'),
        _InfoChip(icon: Icons.work_outline_rounded, label: job.type),
        _InfoChip(icon: Icons.attach_money_rounded, label: job.salary),
        _InfoChip(icon: Icons.access_time_rounded, label: job.postedAt),
      ],
    );
  }

  Widget _buildMatchSection(Job job) {
    final color = job.matchScore >= 80
        ? AppColors.success
        : job.matchScore >= 60
            ? AppColors.warning
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Match Score: ${job.matchScore}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  job.matchScore >= 80
                      ? 'Excellent match! You have most required skills.'
                      : job.matchScore >= 60
                          ? 'Good fit. A few skill gaps to address.'
                          : 'Low match. Consider upskilling first.',
                  style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(Job job) {
    if (job.requiredSkills.isEmpty) return const SizedBox.shrink();
    final userSkills = _currentUser?.skills.map((s) => s.toLowerCase()).toList() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Required Skills',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: job.requiredSkills.map((skill) {
            final hasSkill = userSkills.any((s) => s.contains(skill.toLowerCase()) || skill.toLowerCase().contains(s));
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasSkill
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasSkill
                      ? AppColors.success.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSkill) ...[
                    const Icon(Icons.check_circle_outline,
                        size: 13, color: AppColors.success),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    skill,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: hasSkill ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildApplySection(Job job) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showApplySheet(job),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Apply Now 🚀',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (job.applyUrl.isNotEmpty) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(job.applyUrl);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Center(
                child: Icon(Icons.open_in_new_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showApplySheet(Job job) {
    if (_loadingUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading your profile...')),
      );
      return;
    }

    final userName = _currentUser?.fullName ?? 'Unknown';
    final userEmail = _currentUser?.email ?? '';
    final githubUsername = _currentUser?.githubUsername ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ApplySheet(
        job: job,
        userName: userName,
        userEmail: userEmail,
        githubUsername: githubUsername,
        resumeUrl: '',
        onApply: () async {
          Navigator.pop(ctx);
          await _applyToJob(job);
        },
      ),
    );
  }

  Future<void> _applyToJob(Job job) async {

    // Re-fetch user data for apply
    String userName = _currentUser?.fullName ?? 'Unknown';
    String userEmail = _currentUser?.email ?? '';
    String githubUsername = _currentUser?.githubUsername ?? '';
    String resumeUrl = '';

    // Try to get latest data from Firestore
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final user = await _userService.getUser(firebaseUser.uid);
        if (user != null) {
          userName = user.fullName;
          userEmail = user.email;
        }
      } catch (_) {}
    }

    final result = await _jobService.applyToJob(
      jobId: job.id,
      jobTitle: job.title,
      companyName: job.company,
      applyUrl: job.applyUrl,
      userName: userName,
      userEmail: userEmail.isEmpty ? (firebaseUser?.email ?? '') : userEmail,
      githubUsername: githubUsername,
      resumeUrl: resumeUrl,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.success : AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

// ── Apply Confirmation Sheet ──────────────────────────────────────────────────

class _ApplySheet extends StatefulWidget {
  final Job job;
  final String userName;
  final String userEmail;
  final String githubUsername;
  final String resumeUrl;
  final VoidCallback onApply;

  const _ApplySheet({
    required this.job,
    required this.userName,
    required this.userEmail,
    required this.githubUsername,
    required this.resumeUrl,
    required this.onApply,
  });

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            const Text(
              'Confirm Application',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                children: [
                  const TextSpan(text: 'Your profile will be sent to '),
                  TextSpan(
                    text: widget.job.company,
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' for the '),
                  TextSpan(
                    text: widget.job.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' role.'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _profileRow(Icons.person_outline_rounded, 'Name',
                      widget.userName.isNotEmpty ? widget.userName : 'Not set'),
                  const SizedBox(height: 12),
                  _profileRow(Icons.email_outlined, 'Email',
                      widget.userEmail.isNotEmpty ? widget.userEmail : 'Not set'),
                  if (widget.githubUsername.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _profileRow(Icons.code_rounded, 'GitHub',
                        'github.com/${widget.githubUsername}'),
                  ],
                  const SizedBox(height: 12),
                  _profileRow(
                    Icons.description_outlined,
                    'Resume',
                    widget.resumeUrl.isNotEmpty
                        ? '✅ Attached'
                        : '⚠️ Not uploaded yet',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Apply button
            GestureDetector(
              onTap: _isApplying
                  ? null
                  : () {
                      setState(() => _isApplying = true);
                      widget.onApply();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: _isApplying ? null : AppColors.primaryGradient,
                  color: _isApplying
                      ? AppColors.surfaceVariant
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isApplying
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Center(
                  child: _isApplying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.primary),
                        )
                      : const Text(
                          '✉️  Send Application',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: double.infinity,
                height: 44,
                child: Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
