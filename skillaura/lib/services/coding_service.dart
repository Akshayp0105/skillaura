import 'dart:convert';
import 'package:http/http.dart' as http;

class CodingService {
  static const String _base = 'http://localhost:8000';
  final _client = http.Client();

  Future<List<Map<String, dynamic>>> getCompanies({String search = ''}) async {
    final uri = Uri.parse('$_base/coding/companies')
        .replace(queryParameters: search.isNotEmpty ? {'search': search} : null);
    final r = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(r.body));
    return [];
  }

  Future<List<Map<String, dynamic>>> getQuestions(String companyId, {String difficulty = ''}) async {
    final uri = Uri.parse('$_base/coding/questions/$companyId')
        .replace(queryParameters: difficulty.isNotEmpty ? {'difficulty': difficulty} : null);
    final r = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(r.body));
    return [];
  }

  Future<Map<String, dynamic>?> getQuestionDetail(String questionId) async {
    final r = await _client.get(Uri.parse('$_base/coding/question/$questionId'))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    return null;
  }

  Future<Map<String, dynamic>> runCode({
    required String code,
    required String language,
    List<Map<String, dynamic>> testCases = const [],
    String stdin = '',
  }) async {
    final r = await _client.post(
      Uri.parse('$_base/coding/run'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'code': code,
        'language': language,
        'stdin': stdin,
        'test_cases': testCases,
      }),
    ).timeout(const Duration(seconds: 20));
    if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    return {'error': 'Run failed: ${r.statusCode}', 'results': []};
  }

  Future<Map<String, dynamic>> evaluateCode({
    required String code,
    required String language,
    String? questionId,
  }) async {
    final r = await _client.post(
      Uri.parse('$_base/coding/evaluate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'code': code, 'language': language, 'question_id': questionId}),
    ).timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    return {};
  }

  /// New unified submit endpoint — runs tests + Gemini AI review.
  Future<Map<String, dynamic>> submitCode({
    required String code,
    required String language,
    required String questionId,
    String? userId,
  }) async {
    final r = await _client.post(
      Uri.parse('$_base/coding/submit'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'code': code,
        'language': language,
        'question_id': questionId,
        if (userId != null) 'user_id': userId,
      }),
    ).timeout(const Duration(seconds: 30)); // allow time for Gemini
    if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    return {'error': 'Submit failed: ${r.statusCode}', 'all_passed': false, 'test_results': []};
  }

  Future<List<Map<String, dynamic>>> getAptitudeCategories() async {
    final r = await _client.get(Uri.parse('$_base/aptitude/categories'))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(r.body));
    return [];
  }

  Future<List<Map<String, dynamic>>> getAptitudeQuestions(String categoryId, {int count = 15}) async {
    final session = DateTime.now().millisecondsSinceEpoch ~/ 1000; // unix seconds
    final uri = Uri.parse('$_base/aptitude/questions/$categoryId')
        .replace(queryParameters: {'count': count.toString(), 'session': session.toString()});
    final r = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(r.body));
    return [];
  }

  Future<List<Map<String, dynamic>>> getMockDomains() async {
    final r = await _client.get(Uri.parse('$_base/mocktest/domains'))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(r.body));
    return [];
  }

  Future<List<Map<String, dynamic>>> getMockQuestions(String domainId) async {
    final session = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final uri = Uri.parse('$_base/mocktest/questions/$domainId')
        .replace(queryParameters: {'session': session.toString()});
    final r = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(r.body));
    return [];
  }

  void dispose() => _client.close();
}
