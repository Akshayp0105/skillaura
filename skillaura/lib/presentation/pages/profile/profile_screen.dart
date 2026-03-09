import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_theme.dart';
import '../../../services/user_service.dart';
import '../../../services/resume_service.dart';
import '../../../services/github_service.dart';
import '../../../services/api_service.dart';
import '../../../domain/entities/user.dart';
import '../../../services/github_service.dart' show GitHubRepo;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _githubController = TextEditingController();
  final _jobRoleController = TextEditingController(text: 'flutter developer');
  final UserService _userService = UserService();
  final ResumeService _resumeService = ResumeService();
  final GitHubService _githubService = GitHubService();
  final ApiService _apiService = ApiService();

  UserEntity? _currentUser;
  bool _resumeUploaded = false;
  bool _isLoading = true;
  String _resumeFileName = '';
  int _atsScore = 0;
  List<String> _extractedSkills = [];

  // Skill Gap Analysis states
  String _selectedJobRole = 'flutter developer';
  SkillGapAnalysis? _skillGapAnalysis;
  bool _isLoadingSkillGap = false;
  Map<String, List<String>> _availableJobRoles = {};

  // Job Role Search states
  List<String> _jobRoleSuggestions = [];
  bool _isSearchingJobRoles = false;
  bool _showJobRoleSuggestions = false;
  bool _isCustomJobRole = false;

  // GitHub Integration states
  bool _githubLoading = false;
  String? _githubUsername;
  List<String> _githubSkills = [];
  int _totalRepos = 0;
  int _totalStars = 0;
  String _topLanguage = 'None';
  List<String> _combinedSkills = [];
  List<GitHubRepo> _githubRepos = [];

  // Resume raw text (for skill-gap keyword frequency analysis)
  String _resumeRawText = '';

  // ATS breakdown from ML engine (for pros/cons card)
  Map<String, dynamic> _breakdown = {};

  // Speech AI Analysis states
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  final TextEditingController _speechController = TextEditingController();
  bool _isAnalyzingSpeech = false;

  // Profile photo & banner (base64 data URIs)
  String? _avatarBase64;
  String? _bannerBase64;
  final ImagePicker _imagePicker = ImagePicker();

  // Suggestion source for Autocomplete widget
  static const List<String> _commonJobRoles = [
    'software developer',
    'application developer',
    'systems engineer',
    'platform engineer',
    'cloud engineer',
    'infrastructure engineer',
    'security engineer',
    'security analyst',
    'soc analyst',
    'penetration tester',
    'ethical hacker',
    'malware analyst',
    'digital forensics analyst',
    'cloud security engineer',
    'application security engineer',
    'data analyst',
    'business intelligence analyst',
    'bi developer',
    'data architect',
    'big data engineer',
    'hadoop developer',
    'spark developer',
    'ai engineer',
    'nlp engineer',
    'computer vision engineer',
    'deep learning engineer',
    'robotics engineer',
    'automation engineer',
    'rpa developer',
    'firmware engineer',
    'hardware engineer',
    'chip design engineer',
    'vlsi engineer',
    'fpga engineer',
    'network security engineer',
    'wireless network engineer',
    'telecom engineer',
    'it support engineer',
    'technical support engineer',
    'system administrator',
    'database administrator',
    'oracle dba',
    'sql developer',
    'postgresql developer',
    'mongodb developer',
    'cloud consultant',
    'aws engineer',
    'azure engineer',
    'gcp engineer',
    'kubernetes engineer',
    'docker engineer',
    'microservices architect',
    'api developer',
    'graphql developer',
    'technical architect',
    'solutions architect',
    'enterprise architect',
    'crm developer',
    'salesforce developer',
    'sap consultant',
    'erp consultant',
    'game designer',
    'game tester',
    'ar developer',
    'vr developer',
    'xr developer',
    '3d artist',
    'technical artist',
    'animation engineer',
    'quantitative analyst',
    'fintech engineer',
    'trading systems developer',
    'blockchain architect',
    'smart contract developer',
    'web3 developer',
    'crypto analyst',
    'seo specialist',
    'digital marketing analyst',
    'growth hacker',
    'technical writer',
    'devrel engineer',
    'it auditor',
    'compliance analyst',
    'risk analyst',
    'it project manager',
    'scrum master',
    'agile coach',
    'release manager',
    'build engineer',
    'configuration manager',
    'test engineer',
    'performance tester',
    'manual tester',
    'cloud operations engineer',
    'network administrator',
    'helpdesk technician',
    'it consultant',
    'data governance analyst',
    'information security analyst',
    'cloud administrator',
    'saas developer',
    'paas engineer',
    'iaas engineer',
    'sitecore developer',
    'sharepoint developer',
    'wordpress developer',
    'drupal developer',
    'angular developer',
    'vue.js developer',
    'next.js developer',
    'nuxt.js developer',
    'svelte developer',
    'flutter engineer',
    'ios engineer',
    'android engineer',
    'xamarin developer',
    'ionic developer',
    'electronics engineer',
    'iot developer',
    'iot architect',
    'autonomous systems engineer',
    'automation tester',
    'sdet engineer',
    'embedded firmware developer',
    'power bi developer',
    'tableau developer',
    'data visualization engineer',
    'big data analyst',
    'ml ops engineer',
    'cloud data engineer',
    'data ops engineer',
    'product analyst',
    'technical product manager',
    'program manager',
    'portfolio manager',
    'security consultant',
    'threat intelligence analyst',
    'incident response analyst',
    'network operations engineer',
    'linux administrator',
    'windows administrator',
    'mainframe developer',
    'cobol developer',
    'c++ developer',
    'go developer',
    'rust developer',
    'php developer',
    'kotlin developer',
    'swift developer',
    'react native developer',
    'backend engineer',
    'frontend engineer',
    'full stack engineer',
    'cloud native developer',
    'edge computing engineer',
    'systems analyst',
    'it manager',
    'technology lead',
    'engineering manager',
    'chief technology officer',
    'chief information officer',
    'chief information security officer',
    'data science manager',
    'ai research scientist',
    'research engineer',
    'data modeler',
    'predictive analytics engineer',
    'computer graphics engineer',
    'visual effects engineer',
    'gameplay engineer',
    'level designer',
    'cloud migration engineer',
    'infrastructure architect',
    'technical consultant',
    'implementation engineer',
    'support engineer',
    'customer success engineer',
    'technical account manager',
    'business systems analyst',
    'application support analyst',
    'information systems manager',
    'data center engineer',
    'virtualization engineer',
    'vmware engineer',
    'citrix engineer',
    'it operations manager',
    'process automation engineer',
    'database engineer',
    'data warehouse engineer',
    'etl developer',
    'react architect',
    'java architect',
    'python architect',
    '.net developer',
    '.net core developer',
    'asp.net developer',
    'laravel developer',
    'django developer',
    'flask developer',
    'spring boot developer',
    'microcontroller programmer',
    'robotics programmer',
    'automation programmer',
    'cloud reliability engineer',
    'security operations engineer',
    'cryptography engineer',
    'data privacy engineer',
    'identity access management engineer',
    'sap abap developer',
    'crm consultant',
    'qa analyst',
    'cloud strategist',
    'technical recruiter',
    'it business analyst',
    'systems consultant',
    'digital transformation consultant',
    'software consultant',
    'cloud transformation engineer',
    'technical program manager',
    'data quality analyst',
    'data steward',
    'it governance analyst',
    'knowledge engineer',
    'search engineer',
    'streaming data engineer',
    'video streaming engineer',
    'audio engineer',
    'signal processing engineer',
    'embedded linux engineer',
    'automotive software engineer',
    'avionics engineer',
    'medical device software engineer',
    'health informatics specialist',
    'bioinformatics engineer',
    'computational scientist',
    'gis developer',
    'geospatial analyst',
    'remote sensing engineer',
    'quant developer',
    'algorithm engineer',
    'optimization engineer',
    'performance engineer',
    'reliability engineer',
    'chaos engineer',
    'edge ai engineer',
    'cloud automation engineer',
    'integration engineer',
    'middleware engineer',
    'api integration specialist',
    'saas implementation consultant',
    'no code developer',
    'low code developer',
    'prompt engineer',
    'ai solutions engineer',
    'conversational ai developer',
    'chatbot developer',
    'voice application developer',
    'smart home engineer',
    'wearable technology developer',
    'metaverse developer',
    'digital twin engineer',
    '5g engineer',
    'network planning engineer',
    'data security analyst',
    'cyber threat analyst',
    'red team engineer',
    'blue team engineer',
    'security architect',
    'application performance engineer',
    'technical operations engineer',
    'cloud support engineer',
    'data migration specialist',
    'it infrastructure engineer',
    'systems integration engineer',
    'computer hardware technician',
    'field service engineer',
    'technology analyst',
    'devsecops engineer',
    'cloud compliance engineer',
    'security automation engineer',
    'data pipeline engineer',
    'ml platform engineer',
    'ai infrastructure engineer',
    'data platform engineer',
    'api security engineer',
    'enterprise applications developer',
    'it automation engineer',
    'automation architect',
    'robotics process engineer',
    'data reporting analyst',
    'virtual reality engineer',
    'augmented reality engineer',
    'mixed reality engineer',
    'it systems engineer',
    'distributed systems engineer',
    'cloud backend engineer',
    'frontend architect',
    'user interface engineer',
    'user experience researcher',
    'design technologist',
    'interaction designer',
    'visual designer',
    'motion designer',
    'brand designer',
    'product designer'
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadUserData();
    _loadJobRoles();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  Future<void> _loadJobRoles() async {
    try {
      final roles = await _apiService.getJobRoles();
      if (mounted && roles != null) {
        setState(() {
          _availableJobRoles = roles;
        });
      }
    } catch (e) {
      // Use default roles if API fails
    }
  }

  Future<void> _loadUserData() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? firebaseUser = auth.currentUser;

      if (firebaseUser != null) {
        final user = await _userService.getUser(firebaseUser.uid);
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isLoading = false;
            if (user != null) {
              _resumeFileName = user.resumeScore > 0 ? 'resume.pdf' : '';
              _atsScore = user.resumeScore;
              _extractedSkills = user.skills;
              _combinedSkills = List<String>.from(user.skills);
              _resumeUploaded = user.resumeScore > 0;

              if (user.avatarUrl.isNotEmpty) {
                _avatarBase64 = user.avatarUrl;
              }
              if (user.backgroundImageUrl.isNotEmpty) {
                _bannerBase64 = user.backgroundImageUrl;
              }
            }
          });
          // Load skill gap analysis after user data is loaded
          if (_combinedSkills.isNotEmpty) {
            _analyzeSkillGap();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _speechController.text = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  void _stopListening() async {
    setState(() => _isListening = false);
    await _speechToText.stop();
  }

  Future<void> _analyzeSpeechText() async {
    final text = _speechController.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isAnalyzingSpeech = true);
    final extracted = await _apiService.analyzeProfileText(text);
    
    if (extracted != null && extracted.isNotEmpty) {
      // Find new skills that aren't already in combined skills
      final newSkills = extracted.where((s) => !_combinedSkills.contains(s)).toList();
      
      _mergeSkills(extracted, _combinedSkills);

      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        await _userService.updateUser(
          uid: auth.currentUser!.uid,
          skills: _combinedSkills,
        );
      }
      
      _analyzeSkillGap();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newSkills.isNotEmpty 
              ? 'Added ${newSkills.length} new skill(s): ${newSkills.join(", ")}'
              : 'Analyzed successfully. Skills are already in your profile!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not extract any standard skills from this description.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
    setState(() {
       _isAnalyzingSpeech = false;
       _speechController.clear();
    });
  }

  Future<void> _analyzeSkillGap() async {
    if (_combinedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please add skills first (upload resume or connect GitHub)')),
      );
      return;
    }

    setState(() => _isLoadingSkillGap = true);

    try {
      final result = await _apiService.getSkillGapAnalysis(
        _combinedSkills,
        _selectedJobRole,
        resumeText: _resumeRawText.isNotEmpty ? _resumeRawText : null,
        githubRepos: _githubRepos.isNotEmpty
            ? _githubRepos
                .map((r) => {
                      'name': r.name,
                      'language': r.language ?? '',
                      'description': r.description ?? '',
                      'stargazers_count': r.stargazersCount,
                      'forks_count': r.forksCount,
                    })
                .toList()
            : null,
      );

      if (mounted) {
        setState(() {
          _skillGapAnalysis = result;
          _isLoadingSkillGap = false;
        });

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${result.matchPercentage.toStringAsFixed(0)}% match with $_selectedJobRole'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSkillGap = false);
        String errorMessage = 'Error analyzing skills: $e';

        // Check for common connection errors and provide helpful message
        if (e.toString().contains('Failed to fetch') ||
            e.toString().contains('SocketException')) {
          errorMessage =
              'Cannot connect to server. Make sure the backend is running:\n'
              '1. Open a terminal\n'
              '2. Run: cd skillaura_backend\n'
              '3. Run: python main.py\n'
              '4. Keep the terminal open while using the app';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _uploadResume() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? firebaseUser = auth.currentUser;

      if (firebaseUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to upload resume')),
          );
        }
        return;
      }

      final result = await _resumeService.pickAndProcessResume();

      if (result != null && mounted) {
        await _userService.saveResumeData(
          uid: firebaseUser.uid,
          extractedSkills: result.extractedSkills,
          atsScore: result.atsScore,
        );

        setState(() {
          _resumeUploaded = true;
          _resumeFileName = result.fileName;
          _atsScore = result.atsScore;
          _extractedSkills = result.extractedSkills;
          _resumeRawText = result.rawText;
          _breakdown = result.breakdown;
          _mergeSkills(result.extractedSkills, _githubSkills);
        });

        // Re-analyze skill gap with new skills
        _analyzeSkillGap();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Resume uploaded! Found ${result.extractedSkills.length} skills. ATS Score: ${result.atsScore}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading resume: $e')),
        );
      }
    }
  }

  void _mergeSkills(List<String> fromResume, List<String> fromGithub) {
    Set<String> merged = {};
    merged.addAll(fromResume);
    merged.addAll(fromGithub);
    _combinedSkills = merged.toList();
  }

  Future<void> _pickImage(bool isAvatar) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isAvatar ? 800 : 1600,
        imageQuality: 75,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      // Create data URI scheme
      final dataUri =
          'data:image/${image.name.split('.').last};base64,$base64String';

      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) return;

      // Optimistic UI update
      setState(() {
        if (isAvatar) {
          _avatarBase64 = dataUri;
        } else {
          _bannerBase64 = dataUri;
        }
      });

      // Save to Firestore
      await _userService.updateUser(
        uid: auth.currentUser!.uid,
        avatarUrl: isAvatar ? dataUri : null,
        backgroundImageUrl: !isAvatar ? dataUri : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${isAvatar ? "Profile photo" : "Background banner"} updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(bool isAvatar) async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) return;

    setState(() {
      if (isAvatar) {
        _avatarBase64 = null;
      } else {
        _bannerBase64 = null;
      }
    });

    try {
      await _userService.updateUser(
        uid: auth.currentUser!.uid,
        avatarUrl: isAvatar ? '' : null,
        backgroundImageUrl: !isAvatar ? '' : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${isAvatar ? "Profile photo" : "Background banner"} removed!'),
          ),
        );
      }
    } catch (e) {
      // Revert on error could go here if critical
    }
  }

  void _showImageOptionsDialog(bool isAvatar) {
    final hasImage = isAvatar ? _avatarBase64 != null : _bannerBase64 != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                ),
                title: Text(hasImage ? 'Change Photo' : 'Upload Photo',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isAvatar);
                },
              ),
              if (hasImage) ...[
                const Divider(color: AppColors.surfaceVariant, height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                  ),
                  title: const Text('Remove Photo',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage(isAvatar);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchGitHubData() async {
    String username = _githubController.text.trim();
    if (username.isEmpty) return;

    setState(() => _githubLoading = true);

    try {
      final githubUser = await _githubService.getUser(username);
      if (githubUser == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid GitHub username')),
        );
        setState(() => _githubLoading = false);
        return;
      }

      List<GitHubRepo> repos = await _githubService.getRepos(username);
      List<String> extractedGithubSkills = _githubService.extractSkills(repos);
      int stars = _githubService.getTotalStars(repos);
      String topLang = _githubService.getTopLanguage(repos);

      // Save github username to Firestore
      await _saveGitHubDataToFirestore(username, extractedGithubSkills);

      setState(() {
        _githubUsername = username;
        _totalRepos = repos.length;
        _totalStars = stars;
        _topLanguage = topLang;
        _githubSkills = extractedGithubSkills;
        _githubRepos = repos;
        _mergeSkills(_extractedSkills, extractedGithubSkills);
        _githubLoading = false;
      });

      // Re-analyze skill gap with new skills
      _analyzeSkillGap();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'GitHub analyzed! Found ${extractedGithubSkills.length} skills from ${repos.length} repositories'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
      setState(() => _githubLoading = false);
    }
  }

  Future<void> _saveGitHubDataToFirestore(
      String username, List<String> skills) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        await _userService.updateUser(
          uid: auth.currentUser!.uid,
          githubUsername: username,
          skills: _combinedSkills,
        );
      }
    } catch (e) {
      debugPrint('Error saving GitHub data: $e');
    }
  }

  @override
  void dispose() {
    _githubController.dispose();
    _jobRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner Image or Default Gradient
                  if (_bannerBase64 != null && _bannerBase64!.isNotEmpty)
                    Image.memory(
                      base64Decode(_bannerBase64!.split(',').last),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.purpleGradient,
                      ),
                    ),
                  // Banner Edit Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: SafeArea(
                      child: GestureDetector(
                        onTap: () => _showImageOptionsDialog(false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                  // Profile Info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar with Edit Button
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.surfaceVariant,
                              backgroundImage: _avatarBase64 != null &&
                                      _avatarBase64!.isNotEmpty
                                  ? MemoryImage(base64Decode(
                                      _avatarBase64!.split(',').last))
                                  : null,
                              child: (_avatarBase64 == null ||
                                      _avatarBase64!.isEmpty)
                                  ? Text(
                                      (user?.fullName.isNotEmpty == true)
                                          ? user!.fullName
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _showImageOptionsDialog(true),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.background, width: 2),
                                  ),
                                  child: const Icon(Icons.edit,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.fullName ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          user?.university ?? 'No university set',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSpeechSection(),
                const SizedBox(height: 16),
                _buildResumeSection(),
                const SizedBox(height: 16),
                if (_resumeUploaded && _breakdown.isNotEmpty)
                  _buildResumeAnalysisCard(),
                const SizedBox(height: 20),
                _buildGithubSection(),
                const SizedBox(height: 24),
                _buildSkillsSection(_combinedSkills),
                const SizedBox(height: 24),
                _buildSkillGapSection(),
                const SizedBox(height: 32),
                if (_githubUsername != null && _resumeUploaded)
                  _buildGeneratePortfolioButton(),
                if (_githubUsername == null || !_resumeUploaded)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Upload resume & connect GitHub to generate your public portfolio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechSection() {
    return _SectionCard(
      title: 'AI Analysis',
      subtitle: 'Tell us a bit about yourself to extract your skills',
      icon: Icons.record_voice_over_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _speechController,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. "I enjoy building mobile apps in Flutter and managing databases in Firebase..."\n\nType or use the microphone to speak.',
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: IconButton(
                onPressed: _isListening ? _stopListening : _startListening,
                icon: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: _isListening ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isAnalyzingSpeech ? null : _analyzeSpeechText,
            icon: _isAnalyzingSpeech
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_isAnalyzingSpeech ? 'Analyzing...' : 'Analyze & Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeSection() {
    return _SectionCard(
      title: 'Resume',
      icon: Icons.description_outlined,
      child: Column(
        children: [
          GestureDetector(
            onTap: _uploadResume,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _resumeUploaded
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    color:
                        _resumeUploaded ? AppColors.success : AppColors.primary,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resumeUploaded
                        ? '$_resumeFileName ✓'
                        : 'Tap to upload your Resume',
                    style: TextStyle(
                      color: _resumeUploaded
                          ? AppColors.success
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (!_resumeUploaded)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'PDF, DOCX, or Image, max 5MB',
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 11),
                      ),
                    ),
                  if (_resumeUploaded) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ATS Score: $_atsScore',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Resume Analysis Card (Pros / Cons) ────────────────────────────────────
  Widget _buildResumeAnalysisCard() {
    const categoryMeta = <String, Map<String, Object>>{
      'contact': {
        'label': 'Contact Info',
        'icon': 0xe0b0,
        'max': 20
      }, // Icons.contact_phone_outlined
      'experience': {
        'label': 'Work Experience',
        'icon': 0xef65,
        'max': 25
      }, // Icons.work_outline
      'education': {
        'label': 'Education',
        'icon': 0xe559,
        'max': 15
      }, // Icons.school_outlined
      'skills': {
        'label': 'Technical Skills',
        'icon': 0xe86f,
        'max': 20
      }, // Icons.code
      'projects': {
        'label': 'Projects',
        'icon': 0xef43,
        'max': 10
      }, // Icons.folder_open
      'impact': {
        'label': 'Impact & Metrics',
        'icon': 0xe8e5,
        'max': 5
      }, // Icons.trending_up
      'formatting': {
        'label': 'Formatting',
        'icon': 0xe236,
        'max': 5
      }, // Icons.format_align_left
    };

    final iconMap = {
      'contact': Icons.contact_phone_outlined,
      'experience': Icons.work_outline,
      'education': Icons.school_outlined,
      'skills': Icons.code_rounded,
      'projects': Icons.folder_open_outlined,
      'impact': Icons.trending_up_rounded,
      'formatting': Icons.format_align_left_outlined,
    };

    final List<Widget> rows = [];
    for (final entry in categoryMeta.entries) {
      final catData = _breakdown[entry.key] as Map<String, dynamic>?;
      if (catData == null) continue;
      final score = (catData['score'] as num? ?? 0).toInt();
      final max =
          (catData['max'] as num? ?? (entry.value['max'] as int)).toInt();
      final details = List<String>.from(catData['details'] ?? []);
      rows.add(_AtsCategory(
        icon: iconMap[entry.key] ?? Icons.circle,
        label: entry.value['label'] as String,
        score: score,
        max: max,
        details: details,
      ));
    }

    return _SectionCard(
      title: 'Resume Analysis',
      subtitle: "What's working & what needs improvement",
      icon: Icons.analytics_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient score banner ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Circular score badge
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: _atsScore / 100,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _atsScoreColor(_atsScore),
                          ),
                        ),
                      ),
                      Text(
                        '$_atsScore',
                        style: TextStyle(
                          color: _atsScoreColor(_atsScore),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ATS Score',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _atsScoreLabel(_atsScore),
                        style: TextStyle(
                          color: _atsScoreColor(_atsScore),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _atsScoreColor(_atsScore).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _atsScoreColor(_atsScore).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$_atsScore / 100',
                    style: TextStyle(
                      color: _atsScoreColor(_atsScore),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Category rows ─────────────────────────────────────────────────
          ...rows,
        ],
      ),
    );
  }

  Color _atsScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _atsScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }

  Widget _buildGithubSection() {
    return _SectionCard(
      title: 'GitHub Integration',
      icon: Icons.code_rounded,
      child: Column(
        children: [
          TextFormField(
            controller: _githubController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter GitHub username',
              prefixIcon: const Icon(Icons.alternate_email_rounded,
                  color: AppColors.textHint, size: 18),
              suffixIcon: GestureDetector(
                onTap: _fetchGitHubData,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _githubLoading ? 'Loading...' : 'Fetch',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          if (_githubUsername != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _GitHubStat(label: 'Repositories', value: '$_totalRepos'),
                const SizedBox(width: 10),
                _GitHubStat(label: 'Stars', value: '$_totalStars'),
                const SizedBox(width: 10),
                _GitHubStat(label: 'Top Language', value: _topLanguage),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsSection(List<String> skills) {
    return _SectionCard(
      title: 'Your Skills',
      icon: Icons.psychology_outlined,
      child: skills.isEmpty
          ? const Text('Upload resume or connect GitHub to extract skills',
              style: TextStyle(color: AppColors.textHint))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(skill,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSkillGapSection() {
    return _SectionCard(
      title: 'Skill Gap Analysis',
      subtitle: 'Compare your skills with job requirements',
      icon: Icons.bar_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Role Autocomplete
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _jobRoleController.text),
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) return const Iterable<String>.empty();
              // Combine API roles (keys) + common fallback list
              final apiKeys = _availableJobRoles.keys.toList();
              final allRoles = {...apiKeys, ..._commonJobRoles}.toList();
              return allRoles.where((role) => role.contains(query));
            },
            displayStringForOption: (option) => option
                .split(' ')
                .map((w) =>
                    w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
                .join(' '),
            onSelected: (selection) {
              _jobRoleController.text = selection
                  .split(' ')
                  .map((w) =>
                      w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
                  .join(' ');
              setState(() => _selectedJobRole = selection.toLowerCase());
              _analyzeSkillGap();
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: AppColors.cardBg,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 220, maxWidth: 500),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        final display = option
                            .split(' ')
                            .map((w) => w.isNotEmpty
                                ? w[0].toUpperCase() + w.substring(1)
                                : w)
                            .join(' ');
                        return InkWell(
                          onTap: () => onSelected(option),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.work_outline_rounded,
                                    size: 15, color: AppColors.textHint),
                                const SizedBox(width: 10),
                                Text(
                                  display,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              // Keep _jobRoleController in sync so we can read it elsewhere
              _jobRoleController.text = controller.text;
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: AppColors.textPrimary),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  final trimmed = controller.text.trim();
                  if (trimmed.isNotEmpty) {
                    setState(() => _selectedJobRole = trimmed.toLowerCase());
                  }
                  onFieldSubmitted();
                },
                decoration: InputDecoration(
                  hintText: 'e.g. Flutter Developer, Data Scientist…',
                  hintStyle:
                      const TextStyle(color: AppColors.textHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.work_outline_rounded,
                      color: AppColors.textHint, size: 18),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.6)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Analyze Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _combinedSkills.isEmpty ? null : _analyzeSkillGap,
              icon: _isLoadingSkillGap
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.analytics_outlined, size: 18),
              label:
                  Text(_isLoadingSkillGap ? 'Analyzing...' : 'Analyze Skills'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Match Percentage
          if (_skillGapAnalysis != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Match: ${_skillGapAnalysis!.matchPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _skillGapAnalysis!.matchPercentage >= 60
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_skillGapAnalysis!.matchedSkills.length}/${_skillGapAnalysis!.requiredSkills.length} skills',
                  style:
                      const TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Level legend ──────────────────────────────────────────────
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _LegendDot(color: Color(0xFFF44336), label: 'Missing'),
                SizedBox(width: 8),
                _LegendDot(color: Color(0xFFFF9800), label: 'Low'),
                SizedBox(width: 8),
                _LegendDot(color: Color(0xFFFFC107), label: 'Medium'),
                SizedBox(width: 8),
                _LegendDot(color: Color(0xFF8BC34A), label: 'Interm.'),
                SizedBox(width: 8),
                _LegendDot(color: Color(0xFF4CAF50), label: 'Pro'),
              ],
            ),
            const SizedBox(height: 10),
            
            // ── Skill rows ──────────────────────────────────────────────
            Column(
              children: _skillGapAnalysis!.gapAnalysis
                  .map((item) => _SkillLevelBar(
                        skill: item.skill,
                        levelName: item.levelName,
                        level: item.userLevel,
                      ))
                  .toList(),
            ),

            // Missing Skills Section
            if (_skillGapAnalysis!.missingSkills.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Skills to Learn:',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _skillGapAnalysis!.missingSkills.map((skill) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      skill,
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
            ],
          ] else ...[
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined,
                      size: 48,
                      color: AppColors.textHint.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'Select a job role and click Analyze\nto see your skill gap',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textHint.withValues(alpha: 0.7),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneratePortfolioButton() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final portfolioLink = 'http://localhost:8000/portfolio/$uid';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // View Portfolio button
          GestureDetector(
            onTap: () {
              if (uid.isNotEmpty) context.go('/portfolio/$uid');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6584).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'View Public Portfolio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Copy shareable link
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: portfolioLink));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(children: [
                    Icon(Icons.link_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('Portfolio link copied!', style: TextStyle(color: Colors.white)),
                  ]),
                  backgroundColor: const Color(0xFF6C63FF),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link_rounded, color: Color(0xFF6C63FF), size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      portfolioLink,
                      style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded, color: Color(0xFF6C63FF), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}


// ─── Skill Level Bar ────────────────────────────────────────────────────────

// ─── Skill Level Bar (replaces fl_chart BarChart) ──────────────────────────
class _SkillLevelBar extends StatelessWidget {
  final String skill;
  final String levelName; // 'none','low','medium','intermediate','professional'
  final int level; // 0-4

  const _SkillLevelBar({
    required this.skill,
    required this.levelName,
    required this.level,
  });

  Color get _barColor {
    switch (levelName) {
      case 'professional':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFF8BC34A);
      case 'medium':
        return const Color(0xFFFFC107);
      case 'low':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFFF44336); // none / missing
    }
  }

  String get _label {
    switch (levelName) {
      case 'professional':
        return 'Professional';
      case 'intermediate':
        return 'Intermediate';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'Missing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fraction = level / 4.0; // 0.0 – 1.0
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Skill name
              SizedBox(
                width: 110,
                child: Text(
                  skill,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bar
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return Stack(
                      children: [
                        // Background track
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Filled portion
                        FractionallySizedBox(
                          widthFactor: fraction.clamp(0.03, 1.0),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: _barColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Level label
              SizedBox(
                width: 78,
                child: Text(
                  _label,
                  style: TextStyle(
                    color: _barColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ATS Category Row (Pros / Cons breakdown) ────────────────────────────────
class _AtsCategory extends StatelessWidget {
  final IconData icon;
  final String label;
  final int score;
  final int max;
  final List<String> details;

  const _AtsCategory({
    required this.icon,
    required this.label,
    required this.score,
    required this.max,
    required this.details,
  });

  Color get _barColor {
    final pct = max == 0 ? 0.0 : score / max;
    if (pct >= 0.8) return AppColors.success;
    if (pct >= 0.5) return AppColors.primary;
    if (pct >= 0.25) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final pros = details.where((d) => d.contains('✓')).toList();
    final cons = details.where((d) => d.contains('⚠')).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _barColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _barColor, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _barColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _barColor.withValues(alpha: 0.25)),
              ),
              child: Text('$score / $max',
                  style: TextStyle(
                    color: _barColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  )),
            ),
          ]),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : score / max,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
          if (pros.isNotEmpty || cons.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Pros
            ...pros.map((p) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(
                        p.replaceAll('✓', '').trim(),
                        style: TextStyle(
                          color: AppColors.success.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                    ],
                  ),
                )),
            // Cons
            ...cons.map((c) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppColors.warning, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(
                        c.replaceAll('⚠', '').trim(),
                        style: TextStyle(
                          color: AppColors.warning.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ─── Legend Dot ─────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard(
      {required this.title,
      this.subtitle,
      required this.icon,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _GitHubStat extends StatelessWidget {
  final String label;
  final String value;
  const _GitHubStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: AppColors.textHint, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
