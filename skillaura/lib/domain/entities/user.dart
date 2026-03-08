class UserEntity {
  final String id;
  final String fullName;
  final String email;
  final String university;
  final String avatarUrl;
  final String backgroundImageUrl;
  final List<String> skills;
  final int resumeScore;
  final String githubUsername;
  final int totalInterviewSessions;
  final double averageInterviewScore;
  final int totalInterviewTimeSeconds;
  final double totalScoreAccumulated;
  final bool notificationsEnabled;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.university,
    required this.avatarUrl,
    required this.backgroundImageUrl,
    required this.skills,
    required this.resumeScore,
    this.githubUsername = '',
    this.totalInterviewSessions = 0,
    this.averageInterviewScore = 0.0,
    this.totalInterviewTimeSeconds = 0,
    this.totalScoreAccumulated = 0.0,
    this.notificationsEnabled = false,
  });

  UserEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? university,
    String? avatarUrl,
    String? backgroundImageUrl,
    List<String>? skills,
    int? resumeScore,
    String? githubUsername,
    int? totalInterviewSessions,
    double? averageInterviewScore,
    int? totalInterviewTimeSeconds,
    double? totalScoreAccumulated,
    bool? notificationsEnabled,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      university: university ?? this.university,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      skills: skills ?? this.skills,
      resumeScore: resumeScore ?? this.resumeScore,
      githubUsername: githubUsername ?? this.githubUsername,
      totalInterviewSessions: totalInterviewSessions ?? this.totalInterviewSessions,
      averageInterviewScore: averageInterviewScore ?? this.averageInterviewScore,
      totalInterviewTimeSeconds: totalInterviewTimeSeconds ?? this.totalInterviewTimeSeconds,
      totalScoreAccumulated: totalScoreAccumulated ?? this.totalScoreAccumulated,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}


