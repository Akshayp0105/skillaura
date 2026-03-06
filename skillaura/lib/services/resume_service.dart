import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';

class ResumeService {
  final ApiService _apiService = ApiService();

  static const List<String> knownSkills = [
    'Python',
    'Java',
    'JavaScript',
    'TypeScript',
    'Dart',
    'Flutter',
    'React',
    'Vue',
    'Angular',
    'Node.js',
    'Express',
    'Django',
    'Flask',
    'FastAPI',
    'GraphQL',
    'REST APIs',
    'SQL',
    'MySQL',
    'PostgreSQL',
    'MongoDB',
    'Firebase',
    'Git',
    'Docker',
    'AWS',
    'GCP',
    'Azure',
    'Linux',
    'Machine Learning',
    'Data Science',
    'TensorFlow',
    'PyTorch',
    'Agile',
    'Scrum',
    'OOP',
    'Testing',
    'Kotlin',
    'Swift',
    'Go',
    'Rust',
    'Ruby',
    'PHP',
    'C++',
    'C#',
    'HTML',
    'CSS',
    'SASS',
    'Less',
    'Bootstrap',
    'Tailwind',
    'jQuery',
    'Redux',
    'MobX',
    'Riverpod',
    'BLoC',
    'Provider',
    'GetX',
    'Firebase',
    'Firestore',
    'Supabase',
    'Redis',
    'Elasticsearch',
    'Kafka',
    'RabbitMQ',
    'gRPC',
    'WebSockets',
    'Jest',
    'Mocha',
    'Cypress',
    'Selenium',
    'JUnit',
    'PyTest',
    'REST',
    'Microservices',
    'Docker',
    'Kubernetes',
    'Jenkins',
    'GitHub Actions',
    'CI/CD',
    'DevOps',
    'Agile',
    'Scrum',
    'TDD',
    'OOP',
    'Data Structures',
    'Algorithms',
  ];

  Future<ResumeResult?> pickAndProcessResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'txt', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        final isImage = _isImageFile(fileName);

        if (file.bytes != null) {
          final base64 = base64Encode(file.bytes!);

          // Try API analysis for better results
          try {
            final apiResult = await _apiService.analyzeResumeBase64(
              file.bytes!,
              fileName,
            );

            if (apiResult != null) {
              // Try to decode raw text for skill-gap context
              String rawText = '';
              try {
                rawText = String.fromCharCodes(file.bytes!);
              } catch (_) {}
              return ResumeResult(
                fileName: fileName,
                base64Data: base64,
                extractedSkills: apiResult.skills,
                atsScore: apiResult.atsScore,
                missingSkills: apiResult.missingSkills,
                suggestions: apiResult.suggestions,
                isFromApi: true,
                rawText: rawText,
                breakdown: apiResult.breakdown,
              );
            }
          } catch (e) {
            // Fall back to local extraction if API fails
          }

          // Local extraction fallback
          if (isImage) {
            // For images, we'll do basic text pattern matching on filename
            // In production, you'd want OCR integration
            final skills = _extractSkillsFromFileName(fileName);
            final atsScore = 50 +
                (skills.length * 2).clamp(0, 30); // Lower base score for images
            return ResumeResult(
              fileName: fileName,
              base64Data: base64,
              extractedSkills: skills,
              atsScore: atsScore,
            );
          } else {
            final content = String.fromCharCodes(file.bytes!);
            final skills = extractSkillsFromText(content);
            final atsScore = calculateAtsScore(content, skills);
            return ResumeResult(
              fileName: fileName,
              base64Data: base64,
              extractedSkills: skills,
              atsScore: atsScore,
              rawText: content,
            );
          }
        } else if (file.path != null) {
          final fileObj = File(file.path!);
          final bytes = await fileObj.readAsBytes();
          final base64 = base64Encode(bytes);

          // Try API analysis for better results
          try {
            final apiResult = await _apiService.analyzeResumeBase64(
              bytes,
              fileName,
            );

            if (apiResult != null) {
              String rawText = '';
              try {
                final f2 = File(file.path!);
                rawText = await f2.readAsString();
              } catch (_) {}
              return ResumeResult(
                fileName: fileName,
                base64Data: base64,
                extractedSkills: apiResult.skills,
                atsScore: apiResult.atsScore,
                missingSkills: apiResult.missingSkills,
                suggestions: apiResult.suggestions,
                isFromApi: true,
                rawText: rawText,
              );
            }
          } catch (e) {
            // Fall back to local extraction if API fails
          }

          // Local extraction fallback
          if (isImage) {
            final skills = _extractSkillsFromFileName(fileName);
            final atsScore = 50 + (skills.length * 2).clamp(0, 30);
            return ResumeResult(
              fileName: fileName,
              base64Data: base64,
              extractedSkills: skills,
              atsScore: atsScore,
            );
          } else {
            final content = await _readFileContent(file.path!);
            final skills = extractSkillsFromText(content);
            final atsScore = calculateAtsScore(content, skills);
            return ResumeResult(
              fileName: fileName,
              base64Data: base64,
              extractedSkills: skills,
              atsScore: atsScore,
              rawText: content,
            );
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isImageFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext);
  }

  List<String> _extractSkillsFromFileName(String fileName) {
    // Extract potential skills from the filename if it contains skill keywords
    final lowerName = fileName.toLowerCase();
    final foundSkills = <String>[];

    for (var skill in knownSkills) {
      if (lowerName.contains(skill.toLowerCase())) {
        foundSkills.add(skill);
      }
    }

    return foundSkills.toList()..sort();
  }

  Future<String> _readFileContent(String path) async {
    try {
      if (path.isEmpty) return '';
      final file = File(path);

      // Check if it's an image file
      if (_isImageFile(path)) {
        return ''; // Can't read image as text
      }

      return await file.readAsString();
    } catch (e) {
      return '';
    }
  }

  List<String> extractSkillsFromText(String text) {
    if (text.isEmpty) return [];
    final Set<String> foundSkills = {};
    final lowerText = text.toLowerCase();

    for (var skill in knownSkills) {
      if (lowerText.contains(skill.toLowerCase())) {
        foundSkills.add(skill);
      }
    }
    return foundSkills.toList()..sort();
  }

  int calculateAtsScore(String text, List<String> skills) {
    if (text.isEmpty) return 0;
    int score = 0;
    final lowerText = text.toLowerCase();
    final wordCount = text.split(RegExp(r'\s+')).length;

    if (wordCount > 100) score += 10;
    if (wordCount > 200) score += 10;
    if (wordCount > 400) score += 10;
    if (skills.isNotEmpty) score += (skills.length * 3).clamp(0, 25);
    if (lowerText.contains('experience') || lowerText.contains('work history'))
      score += 10;
    if (lowerText.contains('education') || lowerText.contains('degree'))
      score += 10;
    if (lowerText.contains('project')) score += 10;
    if (lowerText.contains('skill')) score += 5;
    if (lowerText.contains('@')) score += 5;
    if (RegExp(r'\d{10,}').hasMatch(text)) score += 5;
    if (lowerText.contains('responsibilities')) score += 5;
    if (lowerText.contains('achievements')) score += 5;
    if (lowerText.contains('certification') || lowerText.contains('certified'))
      score += 5;

    return score.clamp(0, 100);
  }

  List<String> getImprovementSuggestions(int score, List<String> skills) {
    final suggestions = <String>[];
    if (score < 50) {
      suggestions.add('Add more relevant skills to your resume');
      suggestions.add('Include work experience section');
      suggestions.add('Add your education details');
    } else if (score < 70) {
      suggestions.add('Add more project descriptions');
      suggestions.add('Quantify your achievements with numbers');
    } else if (score < 85) {
      suggestions.add('Add certifications');
      suggestions.add('Include more technical details');
    }
    if (!skills.any((s) => s.toLowerCase() == 'git'))
      suggestions.add('Add version control (Git)');
    if (!skills.any(
        (s) => s.toLowerCase() == 'sql' || s.toLowerCase() == 'database')) {
      suggestions.add('Add database knowledge');
    }
    return suggestions;
  }

  Future<SkillGapAnalysis?> getSkillGapAnalysis(
      List<String> userSkills, String jobRole) async {
    try {
      return await _apiService.getSkillGapAnalysis(userSkills, jobRole);
    } catch (e) {
      return null;
    }
  }
}

class ResumeResult {
  final String fileName;
  final String base64Data;
  final List<String> extractedSkills;
  final int atsScore;
  final List<String> missingSkills;
  final List<String> suggestions;
  final bool isFromApi;

  /// Raw decoded text of the resume (used by skill-gap analysis for keyword frequency).
  final String rawText;

  /// Per-category ATS breakdown from the ML engine.
  final Map<String, dynamic> breakdown;

  ResumeResult({
    required this.fileName,
    required this.base64Data,
    required this.extractedSkills,
    required this.atsScore,
    this.missingSkills = const [],
    this.suggestions = const [],
    this.isFromApi = false,
    this.rawText = '',
    this.breakdown = const {},
  });
}
