import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your server's IP/URL when deploying
  // For local development, use your computer's local IP address
  static const String _baseUrl =
      'http://localhost:8000'; // Windows desktop / iOS simulator
  // static const String _baseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost
  // static const String _baseUrl = 'http://YOUR_IP:8000'; // Physical device

  final http.Client _client = http.Client();

  // ================= RESUME ANALYSIS =================

  /// Analyze resume from base64 encoded content
  Future<ResumeAnalysis?> analyzeResumeBase64(
      Uint8List fileBytes, String fileName) async {
    try {
      final base64Content = base64Encode(fileBytes);

      final response = await _client.post(
        Uri.parse('$_baseUrl/analyze-resume-base64'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': base64Content,
          'file_name': fileName,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ResumeAnalysis.fromJson(data);
      }

      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to analyze resume');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> sendNotification({
    required String email,
    required String subject,
    required String body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'subject': subject,
          'body': body,
        }),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification $e');
      return false;
    }
  }

  // ================= GITHUB ANALYSIS =================

  /// Analyze GitHub profile
  Future<GitHubAnalysis?> analyzeGithub(String username) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/analyze-github'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GitHubAnalysis.fromJson(data);
      }

      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to analyze GitHub');
    } catch (e) {
      rethrow;
    }
  }

  // ================= SKILL GAP ANALYSIS =================

  /// Get skill gap analysis for a job role
  Future<SkillGapAnalysis?> getSkillGapAnalysis(
    List<String> userSkills,
    String jobRole, {
    String? resumeText,
    List<Map<String, dynamic>>? githubRepos,
  }) async {
    try {
      final body = <String, dynamic>{
        'user_skills': userSkills,
        'job_role': jobRole,
      };

      if (resumeText != null && resumeText.isNotEmpty) {
        body['resume_text'] = resumeText;
      }
      if (githubRepos != null && githubRepos.isNotEmpty) {
        body['github_repos'] = githubRepos;
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/skill-gap-analysis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SkillGapAnalysis.fromJson(data);
      }

      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to get skill gap analysis');
    } catch (e) {
      rethrow;
    }
  }

  /// Get available job roles
  Future<Map<String, List<String>>?> getJobRoles() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/job-roles'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, List<String>>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search job roles by query
  Future<List<String>?> searchJobRoles(String query) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/search-job-roles?query=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['roles'] ?? []);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

// ================= RESPONSE MODELS =================

class ResumeAnalysis {
  final List<String> skills;
  final int atsScore;
  final List<String> missingSkills;
  final List<String> suggestions;
  final List<String> topSkills;
  final String? fileName;

  /// Per-category ML breakdown: {category: {score, max, details: [...]}}
  final Map<String, dynamic> breakdown;

  ResumeAnalysis({
    required this.skills,
    required this.atsScore,
    required this.missingSkills,
    required this.suggestions,
    required this.topSkills,
    this.fileName,
    this.breakdown = const {},
  });

  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysis(
      skills: List<String>.from(json['skills'] ?? []),
      atsScore: json['ats_score'] ?? 0,
      missingSkills: List<String>.from(json['missing_skills'] ?? []),
      suggestions: List<String>.from(json['suggestions'] ?? []),
      topSkills: List<String>.from(json['top_skills'] ?? []),
      fileName: json['file_name'],
      breakdown: Map<String, dynamic>.from(json['breakdown'] ?? {}),
    );
  }
}

class GitHubAnalysis {
  final String username;
  final List<String> skills;
  final int totalRepos;
  final int totalStars;
  final String topLanguage;

  GitHubAnalysis({
    required this.username,
    required this.skills,
    required this.totalRepos,
    required this.totalStars,
    required this.topLanguage,
  });

  factory GitHubAnalysis.fromJson(Map<String, dynamic> json) {
    return GitHubAnalysis(
      username: json['username'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      totalRepos: json['total_repos'] ?? 0,
      totalStars: json['total_stars'] ?? 0,
      topLanguage: json['top_language'] ?? 'None',
    );
  }
}

class SkillGapAnalysis {
  final String jobRole;
  final List<String> userSkills;
  final List<String> requiredSkills;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<SkillGapItem> gapAnalysis;
  final double matchPercentage;

  SkillGapAnalysis({
    required this.jobRole,
    required this.userSkills,
    required this.requiredSkills,
    required this.matchedSkills,
    required this.missingSkills,
    required this.gapAnalysis,
    required this.matchPercentage,
  });

  factory SkillGapAnalysis.fromJson(Map<String, dynamic> json) {
    return SkillGapAnalysis(
      jobRole: json['job_role'] ?? '',
      userSkills: List<String>.from(json['user_skills'] ?? []),
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      matchedSkills: List<String>.from(json['matched_skills'] ?? []),
      missingSkills: List<String>.from(json['missing_skills'] ?? []),
      gapAnalysis: (json['gap_analysis'] as List? ?? [])
          .map((item) => SkillGapItem.fromJson(item))
          .toList(),
      matchPercentage: (json['match_percentage'] ?? 0).toDouble(),
    );
  }
}

class SkillGapItem {
  final String skill;
  final int userLevel; // 0-4
  final int requiredLevel; // always 4
  final bool hasSkill;
  final String
      levelName; // 'none' | 'low' | 'medium' | 'intermediate' | 'professional'

  SkillGapItem({
    required this.skill,
    required this.userLevel,
    required this.requiredLevel,
    required this.hasSkill,
    this.levelName = 'none',
  });

  factory SkillGapItem.fromJson(Map<String, dynamic> json) {
    return SkillGapItem(
      skill: json['skill'] ?? '',
      userLevel: json['user_level'] ?? 0,
      requiredLevel: json['required_level'] ?? 4,
      hasSkill: json['has_skill'] ?? false,
      levelName: json['level_name'] ?? 'none',
    );
  }
}
