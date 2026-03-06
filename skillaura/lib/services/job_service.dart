import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/job.dart';

class JobService {
  static const String _baseUrl = 'http://localhost:8000';

  final http.Client _client = http.Client();

  // ── Search live jobs from Adzuna ─────────────────────────────────────────
  Future<JobSearchResult> searchJobs(
    String query, {
    String filter = 'All',
    List<String> userSkills = const [],
    int page = 1,
    String country = 'in',
  }) async {
    try {
      final skillsParam = userSkills.join(',');
      final uri = Uri.parse('$_baseUrl/jobs/search').replace(
        queryParameters: {
          'query': query.isEmpty ? 'software developer' : query,
          'country': country,
          'contract_type': filter == 'All' ? '' : filter,
          'page': page.toString(),
          'results_per_page': '20',
          if (skillsParam.isNotEmpty) 'user_skills': skillsParam,
        },
      );

      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final jobs = (data['jobs'] as List? ?? [])
            .map((j) => Job.fromJson(j as Map<String, dynamic>))
            .toList();
        return JobSearchResult(jobs: jobs, total: data['total'] ?? jobs.length);
      }

      final err = json.decode(response.body);
      throw Exception(err['detail'] ?? 'Job search failed');
    } catch (e) {
      rethrow;
    }
  }

  // ── Autocomplete suggestions ─────────────────────────────────────────────
  Future<List<String>> getSuggestions(
    String query, {
    String country = 'in',
  }) async {
    try {
      if (query.trim().isEmpty) {
        return _popularRoles;
      }

      final uri = Uri.parse('$_baseUrl/jobs/suggest').replace(
        queryParameters: {'query': query, 'country': country},
      );

      final response = await _client.get(uri).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['suggestions'] ?? []);
      }
      return _fallbackSuggestions(query);
    } catch (_) {
      return _fallbackSuggestions(query);
    }
  }

  // ── Apply to a job ───────────────────────────────────────────────────────
  Future<ApplyResult> applyToJob({
    required String jobId,
    required String jobTitle,
    required String companyName,
    required String applyUrl,
    required String userName,
    required String userEmail,
    String resumeUrl = '',
    String githubUsername = '',
    String? coverNote,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/jobs/apply'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'job_id': jobId,
              'job_title': jobTitle,
              'company_name': companyName,
              'apply_url': applyUrl,
              'user_name': userName,
              'user_email': userEmail,
              'resume_url': resumeUrl,
              'github_username': githubUsername,
              'cover_note': coverNote,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApplyResult(
          success: data['success'] == true,
          message: data['message'] ?? 'Application sent!',
        );
      }

      final err = json.decode(response.body);
      return ApplyResult(success: false, message: err['detail'] ?? 'Failed to apply');
    } catch (e) {
      return ApplyResult(success: false, message: 'Network error: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  List<String> _fallbackSuggestions(String query) {
    final q = query.toLowerCase();
    return _popularRoles.where((r) => r.toLowerCase().contains(q)).toList();
  }

  static const List<String> _popularRoles = [
    'Flutter Developer',
    'React Developer',
    'Python Developer',
    'Machine Learning Engineer',
    'Full Stack Developer',
    'Data Scientist',
    'DevOps Engineer',
    'Node.js Developer',
    'Android Developer',
    'iOS Developer',
    'Backend Engineer',
    'Frontend Developer',
    'Data Analyst',
    'Cloud Engineer',
    'Java Developer',
    'UI/UX Designer',
    'Software Engineer',
    'Product Manager',
  ];

  void dispose() => _client.close();
}

// ── Result models ────────────────────────────────────────────────────────────

class JobSearchResult {
  final List<Job> jobs;
  final int total;
  const JobSearchResult({required this.jobs, required this.total});
}

class ApplyResult {
  final bool success;
  final String message;
  const ApplyResult({required this.success, required this.message});
}
