import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class PublicPortfolioScreen extends StatefulWidget {
  final String uid;
  const PublicPortfolioScreen({super.key, required this.uid});

  @override
  State<PublicPortfolioScreen> createState() => _PublicPortfolioScreenState();
}

class _PublicPortfolioScreenState extends State<PublicPortfolioScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;

  String? _fullName;
  String? _university;
  String? _bio;
  String? _avatarBase64;
  String? _bannerBase64;
  String? _githubUsername;
  String? _email;
  List<String> _skills = [];
  int _atsScore = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fetchUserData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      if (!doc.exists) {
        setState(() { _error = 'User not found'; _isLoading = false; });
        return;
      }
      final data = doc.data()!;
      setState(() {
        _fullName        = data['fullName'] as String?;
        _university      = data['university'] as String?;
        _bio             = data['bio'] as String?;
        _email           = data['email'] as String?;
        _avatarBase64    = data['avatarBase64'] as String?;
        _bannerBase64    = data['bannerBase64'] as String?;
        _githubUsername  = data['githubUsername'] as String?;
        _skills          = data['skills'] != null ? List<String>.from(data['skills']) : [];
        _atsScore        = (data['resumeScore'] as int?) ?? 0;
        _isLoading       = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      setState(() { _error = 'Failed to load portfolio'; _isLoading = false; });
    }
  }

  /// Safely decode a base64 or data-URI string into bytes
  Uint8List? _decodeImage(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      if (raw.startsWith('data:')) {
        return UriData.parse(raw).contentAsBytes();
      }
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  String get _shareableLink => 'https://skillaura.vercel.app/portfolio/${widget.uid}';
  // For production: 'https://skillaura.app/portfolio/${widget.uid}'

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _shareableLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.link_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('Portfolio link copied!', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ],
          ),
        ),
      );
    }

    final avatarBytes = _decodeImage(_avatarBase64);
    final bannerBytes = _decodeImage(_bannerBase64);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Hero Banner ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.background,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'Copy share link',
                  onPressed: _copyLink,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Banner image or gradient
                    if (bannerBytes != null)
                      Image.memory(bannerBytes, fit: BoxFit.cover)
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF3A1CC4), Color(0xFFFF6584)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    // Bottom gradient for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    // Profile info overlay
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 70,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar with border glow
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: AppColors.surfaceVariant,
                              backgroundImage:
                                  avatarBytes != null ? MemoryImage(avatarBytes) : null,
                              child: avatarBytes == null
                                  ? Text(
                                      (_fullName?.isNotEmpty == true)
                                          ? _fullName![0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _fullName ?? 'Unknown User',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.3),
                                ),
                                if (_university != null) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.school_outlined,
                                          color: Colors.white70, size: 13),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _university!,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white70),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Shareable Link Card ─────────────────────────────────
                  _ShareLinkCard(link: _shareableLink, onCopy: _copyLink),
                  const SizedBox(height: 16),

                  // ── Bio card ───────────────────────────────────────────
                  if (_bio != null && _bio!.isNotEmpty) ...[
                    _SectionCard(
                      icon: Icons.person_outline_rounded,
                      title: 'About',
                      child: Text(
                        _bio!,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── ATS Score ──────────────────────────────────────────
                  if (_atsScore > 0) ...[
                    _buildResumeCard(),
                    const SizedBox(height: 16),
                  ],

                  // ── Skills ─────────────────────────────────────────────
                  if (_skills.isNotEmpty) ...[
                    _buildSkillsCard(),
                    const SizedBox(height: 16),
                  ],

                  // ── GitHub ─────────────────────────────────────────────
                  if (_githubUsername != null && _githubUsername!.isNotEmpty) ...[
                    _buildGithubCard(),
                    const SizedBox(height: 16),
                  ],

                  // ── Contact ────────────────────────────────────────────
                  if (_email != null && _email!.isNotEmpty) ...[
                    _SectionCard(
                      icon: Icons.email_outlined,
                      title: 'Contact',
                      child: GestureDetector(
                        onTap: () => launchUrl(Uri.parse('mailto:$_email')),
                        child: Text(
                          _email!,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Footer ─────────────────────────────────────────────
                  _buildFooter(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── GitHub Card ─────────────────────────────────────────────────────────────
  Widget _buildGithubCard() {
    return _SectionCard(
      icon: Icons.code_rounded,
      title: 'GitHub',
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 18),
        onPressed: () => launchUrl(Uri.parse('https://github.com/$_githubUsername')),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('https://github.com/$_githubUsername')),
            child: Text(
              '@$_githubUsername',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              'https://github-readme-stats.vercel.app/api?username=$_githubUsername'
              '&show_icons=true&theme=dark&hide_border=true&bg_color=1c192b'
              '&icon_color=6C63FF&title_color=ffffff&text_color=aaaaaa',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('GitHub stats unavailable',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ATS Score Card ──────────────────────────────────────────────────────────
  Widget _buildResumeCard() {
    final Color scoreColor =
        _atsScore >= 80 ? AppColors.success : (_atsScore >= 60 ? AppColors.warning : AppColors.error);
    final String label =
        _atsScore >= 80 ? 'Excellent' : _atsScore >= 60 ? 'Good' : 'Needs Work';

    return _SectionCard(
      icon: Icons.description_outlined,
      title: 'Resume ATS Score',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: scoreColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _atsScore / 100,
                    backgroundColor: AppColors.surfaceVariant,
                    color: scoreColor,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Competitively ranked vs industry standards.',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 3),
              color: scoreColor.withValues(alpha: 0.1),
            ),
            alignment: Alignment.center,
            child: Text(
              '$_atsScore',
              style: TextStyle(
                  color: scoreColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ── Skills Card ─────────────────────────────────────────────────────────────
  Widget _buildSkillsCard() {
    return _SectionCard(
      icon: Icons.psychology_outlined,
      title: 'Top Skills',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _skills
            .map((s) => _SkillChip(label: s))
            .toList(),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Made with SkillAura ✨',
          style: TextStyle(
              color: AppColors.textHint,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => launchUrl(Uri.parse('https://skillaura.app')),
          child: const Text('Create your own portfolio →',
              style: TextStyle(color: AppColors.primary, fontSize: 13)),
        ),
      ],
    );
  }
}

// ── Share Link Card ─────────────────────────────────────────────────────────────
class _ShareLinkCard extends StatelessWidget {
  final String link;
  final VoidCallback onCopy;
  const _ShareLinkCard({required this.link, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            const Color(0xFFFF6584).withValues(alpha: 0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Portfolio Link',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  link,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Copy', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Card ────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Skill Chip ──────────────────────────────────────────────────────────────────
class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  // Assign distinct colors by cycling through a palette
  Color _color() {
    const colors = [
      Color(0xFF6C63FF), Color(0xFFFF6584), Color(0xFF43E97B),
      Color(0xFF4FACFE), Color(0xFFFFBB00), Color(0xFFFF4757),
    ];
    return colors[label.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: c,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
