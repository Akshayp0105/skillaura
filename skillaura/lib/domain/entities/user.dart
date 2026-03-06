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
    );
  }
}


