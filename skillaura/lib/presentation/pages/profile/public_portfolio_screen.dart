import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class PublicPortfolioScreen extends StatefulWidget {
  final String uid;

  const PublicPortfolioScreen({super.key, required this.uid});

  @override
  State<PublicPortfolioScreen> createState() => _PublicPortfolioScreenState();
}

class _PublicPortfolioScreenState extends State<PublicPortfolioScreen> {
  bool _isLoading = true;
  String? _error;
  
  String? _fullName;
  String? _university;
  String? _avatarBase64;
  String? _bannerBase64;
  
  String? _githubUsername;
  List<String> _skills = [];
  int _atsScore = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (!doc.exists) {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
        return;
      }
      
      final data = doc.data()!;
      setState(() {
        _fullName = data['fullName'] as String?;
        _university = data['university'] as String?;
        _avatarBase64 = data['avatarBase64'] as String?;
        _bannerBase64 = data['bannerBase64'] as String?;
        _githubUsername = data['githubUsername'] as String?;
        
        if (data['skills'] != null) {
           _skills = List<String>.from(data['skills']);
        }
        _atsScore = data['resumeScore'] as int? ?? 0;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load portfolio';
        _isLoading = false;
      });
    }
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Banner & Profile Info
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   // Banner Image or Default Gradient
                  if (_bannerBase64 != null && _bannerBase64!.isNotEmpty)
                    Image.memory(
                       // base64 decode logic, safe handling data uri
                       UriData.parse(_bannerBase64!).contentAsBytes(),
                       fit: BoxFit.cover,
                    )
                  else
                    Container(decoration: const BoxDecoration(gradient: AppColors.purpleGradient)),
                  
                  // Gradient overlay to make text readable
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                      ),
                    ),
                  ),
                  
                  // Profile Info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.surfaceVariant,
                          backgroundImage: _avatarBase64 != null && _avatarBase64!.isNotEmpty
                              ? MemoryImage(UriData.parse(_avatarBase64!).contentAsBytes())
                              : null,
                          child: (_avatarBase64 == null || _avatarBase64!.isEmpty)
                              ? Text(
                                  (_fullName?.isNotEmpty == true) ? _fullName!.substring(0, 1).toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _fullName ?? 'Unknown User',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _university ?? 'Developer',
                              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_githubUsername != null) _buildGithubCard(),
                const SizedBox(height: 20),
                if (_atsScore > 0) _buildResumeCard(),
                const SizedBox(height: 20),
                _buildSkillsCard(),
                const SizedBox(height: 60),
                _buildFooter(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGithubCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                 child: Text('GitHub Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, color: AppColors.textSecondary, size: 20),
                onPressed: () {
                  launchUrl(Uri.parse('https://github.com/$_githubUsername'));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '@$_githubUsername',
            style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          // A nice github stats image from an external service
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://github-readme-stats.vercel.app/api?username=$_githubUsername&show_icons=true&theme=dracula&hide_border=true&bg_color=1c192b',
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeCard() {
    Color scoreColor = _atsScore >= 80 ? AppColors.success : (_atsScore >= 60 ? AppColors.warning : AppColors.error);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description_outlined, color: AppColors.primary, size: 24),
                    SizedBox(width: 12),
                    Text('Resume ATS Score', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Competitively ranked profile based on industry standards.', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
              ],
            ),
          ),
           Container(
             width: 70,
             height: 70,
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               border: Border.all(color: scoreColor, width: 4),
             ),
             alignment: Alignment.center,
             child: Text(
               '$_atsScore',
               style: TextStyle(color: scoreColor, fontSize: 24, fontWeight: FontWeight.bold),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    if (_skills.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_outlined, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Text('Top Skills', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                skill,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text('Made with SkillAura ✨', style: TextStyle(color: AppColors.textHint, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => launchUrl(Uri.parse('https://skillaura.com')),
          child: const Text('Create your own portfolio', style: TextStyle(color: AppColors.primary)),
        )
      ],
    );
  }
}
