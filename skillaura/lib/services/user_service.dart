import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<void> saveUser({
    required String uid,
    required String fullName,
    required String email,
    required String university,
  }) async {
    final userData = {
      'id': uid,
      'fullName': fullName,
      'email': email.trim(),
      'university': university,
      'avatarUrl': '',
      'backgroundImageUrl': '',
      'skills': <String>[],
      'resumeScore': 0.0,
      'resumeBase64': '',
      'resumeName': '',
      'githubUsername': '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _usersCollection.doc(uid).set(userData);
  }

  Future<UserEntity?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      final data = doc.data() as Map<String, dynamic>;
      return UserEntity(
        id: data['id'] ?? '',
        fullName: data['fullName'] ?? '',
        email: data['email'] ?? '',
        university: data['university'] ?? '',
        avatarUrl: data['avatarUrl'] ?? '',
        backgroundImageUrl: data['backgroundImageUrl'] ?? '',
        skills: List<String>.from(data['skills'] ?? []),
        resumeScore: (data['resumeScore'] ?? 0).toInt(),
        githubUsername: data['githubUsername'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveResumeData({
    required String uid,
    List<String>? extractedSkills,
    required int atsScore,
  }) async {
    final updates = {
      'skills': extractedSkills,
      'resumeScore': atsScore.toDouble(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _usersCollection.doc(uid).update(updates);
  }

Future<void> updateUser({
    required String uid,
    String? fullName,
    String? university,
    String? avatarUrl,
    String? backgroundImageUrl,
    List<String>? skills,
    int? resumeScore,
    String? githubUsername,
  }) async {
    final Map<String, dynamic> updates = {};
    if (fullName != null) {
      updates['fullName'] = fullName;
    }
    if (university != null) {
      updates['university'] = university;
    }
    if (avatarUrl != null) {
      updates['avatarUrl'] = avatarUrl;
    }
    if (backgroundImageUrl != null) {
      updates['backgroundImageUrl'] = backgroundImageUrl;
    }
    if (skills != null) {
      updates['skills'] = skills;
    }
    if (resumeScore != null) {
      updates['resumeScore'] = resumeScore;
    }
    if (githubUsername != null) {
      updates['githubUsername'] = githubUsername;
    }
    if (updates.isNotEmpty) {
      await _usersCollection.doc(uid).update(updates);
    }
  }
}
