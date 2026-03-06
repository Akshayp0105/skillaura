import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubService {
  static const String _baseUrl = 'https://api.github.com';

  /// Fetches GitHub user profile data
  Future<GitHubUser?> getUser(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GitHubUser.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetches user's repositories
  Future<List<GitHubRepo>> getRepos(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username/repos?sort=updated&per_page=100'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((repo) => GitHubRepo.fromJson(repo)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Analyzes GitHub data to extract skills from languages AND repository descriptions
  List<String> extractSkills(List<GitHubRepo> repos) {
    final Map<String, int> languageCount = {};
    final Set<String> skillsFromDescription = {};
    
    // Skills to look for in repository descriptions
    final Map<String, String> descriptionSkillKeywords = {
      'flutter': 'Flutter',
      'firebase': 'Firebase',
      'rest api': 'REST APIs',
      'graphql': 'GraphQL',
      'machine learning': 'Machine Learning',
      'tensorflow': 'TensorFlow',
      'pytorch': 'PyTorch',
      'docker': 'Docker',
      'kubernetes': 'Kubernetes',
      'aws': 'AWS',
      'azure': 'Azure',
      'gcp': 'GCP',
      'mongodb': 'MongoDB',
      'postgresql': 'PostgreSQL',
      'mysql': 'MySQL',
      'redis': 'Redis',
      'express': 'Express',
      'node.js': 'Node.js',
      'react': 'React',
      'vue': 'Vue',
      'angular': 'Angular',
      'django': 'Django',
      'flask': 'Flask',
      'fastapi': 'FastAPI',
      'spring': 'Spring',
      'laravel': 'Laravel',
      'ci/cd': 'CI/CD',
      'jenkins': 'Jenkins',
      'git': 'Git',
      'github actions': 'GitHub Actions',
      'testing': 'Testing',
      'unit test': 'Unit Testing',
      'jest': 'Jest',
      'mocha': 'Mocha',
      'pytest': 'PyTest',
      'junit': 'JUnit',
      'agile': 'Agile',
      'scrum': 'Scrum',
      'figma': 'Figma',
      'ui/ux': 'UI/UX',
      'redux': 'Redux',
      'mobx': 'MobX',
      'riverpod': 'Riverpod',
      'bloc': 'BLoC',
      'provider': 'Provider',
      'getx': 'GetX',
      'sqlite': 'SQLite',
      'firestore': 'Firebase',
      'supabase': 'Supabase',
      'prisma': 'Prisma',
      'typeorm': 'TypeORM',
      'hibernate': 'Hibernate',
      'maven': 'Maven',
      'gradle': 'Gradle',
      'webpack': 'Webpack',
      'vite': 'Vite',
      'tailwind': 'Tailwind',
      'bootstrap': 'Bootstrap',
      'sass': 'SASS',
      'less': 'LESS',
      'nginx': 'Nginx',
      'apache': 'Apache',
      'linux': 'Linux',
      'bash': 'Bash',
      'devops': 'DevOps',
      'microservices': 'Microservices',
      'api': 'REST APIs',
      'crud': 'REST APIs',
    };

    for (var repo in repos) {
      // Count languages
      if (repo.language != null && repo.language!.isNotEmpty) {
        languageCount[repo.language!] = (languageCount[repo.language!] ?? 0) + 1;
      }
      
      // Extract skills from description
      if (repo.description != null && repo.description!.isNotEmpty) {
        final lowerDesc = repo.description!.toLowerCase();
        for (var entry in descriptionSkillKeywords.entries) {
          if (lowerDesc.contains(entry.key)) {
            skillsFromDescription.add(entry.value);
          }
        }
      }
    }

    // Map programming languages to skill names
    final Map<String, String> languageToSkill = {
      'Dart': 'Flutter',
      'JavaScript': 'JavaScript',
      'TypeScript': 'TypeScript',
      'Python': 'Python',
      'Java': 'Java',
      'Kotlin': 'Kotlin',
      'Swift': 'Swift',
      'Go': 'Go',
      'Rust': 'Rust',
      'C++': 'C++',
      'C#': 'C#',
      'Ruby': 'Ruby',
      'PHP': 'PHP',
      'HTML': 'HTML',
      'CSS': 'CSS',
      'SQL': 'SQL',
      'Shell': 'Shell',
    };

    final List<String> skills = [];
    
    // Add skills from languages
    for (var entry in languageCount.entries) {
      if (languageToSkill.containsKey(entry.key)) {
        skills.add(languageToSkill[entry.key]!);
      } else {
        skills.add(entry.key);
      }
    }
    
    // Add skills from descriptions
    skills.addAll(skillsFromDescription);

    // Add Git-related skills based on repo activity
    if (repos.isNotEmpty) {
      skills.add('Git');
    }

    // Remove duplicates and return
    return skills.toSet().toList()..sort();
  }

  /// Gets top language from repositories
  String getTopLanguage(List<GitHubRepo> repos) {
    final Map<String, int> languageCount = {};
    
    for (var repo in repos) {
      if (repo.language != null && repo.language!.isNotEmpty) {
        languageCount[repo.language!] = (languageCount[repo.language!] ?? 0) + 1;
      }
    }

    if (languageCount.isEmpty) return 'None';

    final topEntry = languageCount.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return topEntry.key;
  }

  /// Gets total stars across all repos
  int getTotalStars(List<GitHubRepo> repos) {
    return repos.fold(0, (sum, repo) => sum + (repo.stargazersCount ?? 0));
  }
}

class GitHubUser {
  final String login;
  final String? name;
  final String? avatarUrl;
  final int publicRepos;
  final int followers;
  final int following;

  GitHubUser({
    required this.login,
    this.name,
    this.avatarUrl,
    required this.publicRepos,
    required this.followers,
    required this.following,
  });

  factory GitHubUser.fromJson(Map<String, dynamic> json) {
    return GitHubUser(
      login: json['login'] ?? '',
      name: json['name'],
      avatarUrl: json['avatar_url'],
      publicRepos: json['public_repos'] ?? 0,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
    );
  }
}

class GitHubRepo {
  final String name;
  final String? description;
  final String? language;
  final int stargazersCount;
  final int forksCount;
  final String htmlUrl;

  GitHubRepo({
    required this.name,
    this.description,
    this.language,
    this.stargazersCount = 0,
    this.forksCount = 0,
    required this.htmlUrl,
  });

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    return GitHubRepo(
      name: json['name'] ?? '',
      description: json['description'],
      language: json['language'],
      stargazersCount: json['stargazers_count'] ?? 0,
      forksCount: json['forks_count'] ?? 0,
      htmlUrl: json['html_url'] ?? '',
    );
  }
}
