class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String fullDescription;
  final List<String> requiredSkills;
  final int matchScore;
  final String type; // Remote, Hybrid, On-site
  final String salary;
  final String logo;
  final bool saved;
  final String postedAt;
  // Live job fields
  final String externalId;
  final String applyUrl;
  final String category;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    this.fullDescription = '',
    required this.requiredSkills,
    required this.matchScore,
    required this.type,
    required this.salary,
    required this.logo,
    this.saved = false,
    required this.postedAt,
    this.externalId = '',
    this.applyUrl = '',
    this.category = 'Tech',
  });

  Job copyWith({bool? saved}) {
    return Job(
      id: id,
      title: title,
      company: company,
      location: location,
      description: description,
      fullDescription: fullDescription,
      requiredSkills: requiredSkills,
      matchScore: matchScore,
      type: type,
      salary: salary,
      logo: logo,
      saved: saved ?? this.saved,
      postedAt: postedAt,
      externalId: externalId,
      applyUrl: applyUrl,
      category: category,
    );
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id']?.toString() ?? '',
      externalId: json['external_id']?.toString() ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      fullDescription: json['full_description'] ?? json['description'] ?? '',
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      matchScore: (json['match_score'] ?? 50).toInt(),
      type: json['type'] ?? 'Hybrid',
      salary: json['salary'] ?? 'Salary not disclosed',
      logo: json['logo'] ?? '?',
      saved: json['saved'] ?? false,
      postedAt: json['posted_at'] ?? 'Recently',
      applyUrl: json['apply_url'] ?? '',
      category: json['category'] ?? 'Tech',
    );
  }
}
