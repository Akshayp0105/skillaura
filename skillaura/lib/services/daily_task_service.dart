import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class DailyTaskService {
  static const String _base = 'http://localhost:8000';
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Streak ──────────────────────────────────────────────────────────────────
  static Future<Map<String, int>> getStreak(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).collection('streak').doc('data').get();
      if (doc.exists) {
        final d = doc.data()!;
        return {
          'current': (d['currentStreak'] ?? 0) as int,
          'longest': (d['longestStreak'] ?? 0) as int,
        };
      }
    } catch (_) {}
    return {'current': 0, 'longest': 0};
  }

  // ── Fetch or generate today's tasks ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getTodayTasks({
    required String uid,
    required List<String> skills,
    required int resumeScore,
  }) async {
    final today = _todayStr();

    // 1. Check Firestore cache
    try {
      final doc = await _db
          .collection('users').doc(uid)
          .collection('dailyTasks').doc(today)
          .get();
      if (doc.exists && doc.data()?['tasks'] != null) {
        return List<Map<String, dynamic>>.from(
          (doc.data()!['tasks'] as List).map((t) => Map<String, dynamic>.from(t as Map)),
        );
      }
    } catch (_) {}

    // 2. Get current streak
    final streak = await getStreak(uid);

    // 3. Generate from backend
    try {
      final r = await http.post(
        Uri.parse('$_base/daily/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': uid,
          'skills': skills,
          'streak': streak['current'] ?? 0,
          'resume_score': resumeScore,
          'today': today,
        }),
      ).timeout(const Duration(seconds: 20));

      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        final tasks = List<Map<String, dynamic>>.from(
          (data['tasks'] as List).map((t) => Map<String, dynamic>.from(t as Map)),
        );

        // 4. Cache in Firestore
        await _db
            .collection('users').doc(uid)
            .collection('dailyTasks').doc(today)
            .set({
          'tasks': tasks,
          'completedAll': false,
          'difficulty': data['difficulty'],
          'generatedAt': FieldValue.serverTimestamp(),
        });

        return tasks;
      }
    } catch (_) {}

    // 5. Last resort: return static fallback
    return _fallbackTasks();
  }

  // ── Mark a task as done ──────────────────────────────────────────────────────
  static Future<bool> markTaskDone({
    required String uid,
    required String taskId,
    required List<Map<String, dynamic>> allTasks,
  }) async {
    final today = _todayStr();
    final ref = _db.collection('users').doc(uid).collection('dailyTasks').doc(today);

    // Update the done flag on the matching task
    final updated = allTasks.map((t) {
      if (t['id'] == taskId) return {...t, 'done': true};
      return t;
    }).toList();

    final allDone = updated.every((t) => t['done'] == true);

    try {
      await ref.update({'tasks': updated, 'completedAll': allDone});

      // Update streak if all tasks completed
      if (allDone) await _updateStreak(uid);
    } catch (_) {}

    return allDone;
  }

  // ── Mark a task as undone ────────────────────────────────────────────────────
  static Future<void> unmarkTask({
    required String uid,
    required String taskId,
    required List<Map<String, dynamic>> allTasks,
  }) async {
    final today = _todayStr();
    final ref = _db.collection('users').doc(uid).collection('dailyTasks').doc(today);
    final updated = allTasks.map((t) {
      if (t['id'] == taskId) return {...t, 'done': false};
      return t;
    }).toList();
    try {
      await ref.update({'tasks': updated, 'completedAll': false});
    } catch (_) {}
  }

  // ── Streak update ─────────────────────────────────────────────────────────────
  static Future<void> _updateStreak(String uid) async {
    final today = _todayStr();
    final streakRef = _db.collection('users').doc(uid).collection('streak').doc('data');

    try {
      final doc = await streakRef.get();
      int current = 1;
      int longest = 1;
      if (doc.exists) {
        final d = doc.data()!;
        final last = d['lastCompletedDate'] as String? ?? '';
        final prevCurrent = (d['currentStreak'] ?? 0) as int;
        final prevLongest = (d['longestStreak'] ?? 0) as int;

        if (last == _yesterday()) {
          // Continuing streak
          current = prevCurrent + 1;
        } else if (last == today) {
          // Already updated today
          return;
        }
        // else streak broken, reset to 1
        longest = current > prevLongest ? current : prevLongest;
      }
      await streakRef.set({
        'currentStreak': current,
        'longestStreak': longest,
        'lastCompletedDate': today,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _yesterday() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }

  static List<Map<String, dynamic>> _fallbackTasks() => [
    {'id': 'coding_q001', 'title': 'Solve: Two Sum', 'subtitle': 'Easy · Array · Google', 'type': 'coding', 'difficulty': 'Easy', 'route': 'interview/coding-prep', 'question_id': 'q001', 'company_id': 'google', 'done': false},
    {'id': 't_aptitude', 'title': 'Complete Aptitude Practice', 'subtitle': 'Sharpen your problem-solving skills', 'type': 'aptitude', 'difficulty': 'Easy', 'route': 'interview/aptitude', 'done': false},
    {'id': 't_english', 'title': 'English Communication Session', 'subtitle': 'Practice professional communication', 'type': 'english', 'difficulty': 'Easy', 'route': 'interview/english-practice', 'done': false},
    {'id': 't_jobs', 'title': 'Apply to 2 Internships', 'subtitle': 'Find matching job opportunities', 'type': 'jobs', 'difficulty': 'Easy', 'route': 'jobs', 'done': false},
    {'id': 't_mock', 'title': 'Take a Mock Interview', 'subtitle': 'AI-powered interview simulation', 'type': 'interview', 'difficulty': 'Easy', 'route': 'interview/mock-interview', 'done': false},
  ];
}
