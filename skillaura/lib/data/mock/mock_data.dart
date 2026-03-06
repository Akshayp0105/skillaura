import '../../domain/entities/job.dart';
import '../../domain/entities/user.dart';

class MockData {
  MockData._();

  static const UserEntity currentUser = UserEntity(
    id: 'user-001',
    fullName: 'Arjun Sharma',
    email: 'arjun.sharma@bits.edu',
    university: 'BITS Pilani',
    avatarUrl: '',
    backgroundImageUrl: '',
    skills: ['Flutter', 'Dart', 'Python', 'Firebase', 'REST APIs', 'Git'],
    resumeScore: 74,
  );

  static final List<Job> jobs = [
    const Job(
      id: 'job-001',
      title: 'Flutter Developer Intern',
      company: 'Razorpay',
      location: 'Bangalore',
      description:
          'Work with our mobile team to build and maintain the Razorpay Flutter SDK. You will write clean, testable code and collaborate with senior engineers on real payment features used by millions.',
      requiredSkills: ['Flutter', 'Dart', 'REST APIs', 'Git', 'BLoC'],
      matchScore: 92,
      type: 'Hybrid',
      salary: '₹40,000/mo',
      logo: 'R',
      postedAt: '2 days ago',
    ),
    const Job(
      id: 'job-002',
      title: 'ML Research Intern',
      company: 'Google DeepMind',
      location: 'Remote',
      description:
          'Assist our research team in implementing and testing machine learning models focused on NLP. Ideal for students with strong Python skills and an understanding of transformer architectures.',
      requiredSkills: ['Python', 'PyTorch', 'NLP', 'NumPy', 'Transformers'],
      matchScore: 61,
      type: 'Remote',
      salary: '₹70,000/mo',
      logo: 'G',
      postedAt: '1 day ago',
    ),
    const Job(
      id: 'job-003',
      title: 'Backend Engineer Intern',
      company: 'CRED',
      location: 'Bangalore',
      description:
          'Build microservices for our core financial platform using Go and Kafka. You will work with massive-scale systems handling over 10 million transactions daily.',
      requiredSkills: ['Go', 'Kafka', 'PostgreSQL', 'Docker', 'gRPC'],
      matchScore: 48,
      type: 'On-site',
      salary: '₹55,000/mo',
      logo: 'C',
      postedAt: '5 days ago',
    ),
    const Job(
      id: 'job-004',
      title: 'Full Stack Intern',
      company: 'Swiggy',
      location: 'Hyderabad',
      description:
          'Join Swiggy\'s consumer tech team to build features on our web and mobile platform. Work on React frontend and Node.js services serving 80M+ users.',
      requiredSkills: ['React', 'Node.js', 'TypeScript', 'MongoDB', 'Redis'],
      matchScore: 55,
      type: 'Hybrid',
      salary: '₹45,000/mo',
      logo: 'S',
      postedAt: '3 days ago',
    ),
    const Job(
      id: 'job-005',
      title: 'iOS Developer Intern',
      company: 'PhonePe',
      location: 'Pune',
      description:
          'Help build and maintain features in the PhonePe iOS app. Strong understanding of SwiftUI and UIKit required. Experience with payment flows is a bonus.',
      requiredSkills: ['Swift', 'SwiftUI', 'Xcode', 'Core Data', 'REST APIs'],
      matchScore: 35,
      type: 'On-site',
      salary: '₹38,000/mo',
      logo: 'P',
      postedAt: '1 week ago',
    ),
    const Job(
      id: 'job-006',
      title: 'Data Science Intern',
      company: 'Flipkart',
      location: 'Remote',
      description:
          'Analyze user behavior data to provide insights that improve recommendation accuracy and reduce return rates. Work with our data engineering team on PySpark pipelines.',
      requiredSkills: ['Python', 'PySpark', 'SQL', 'Tableau', 'Statistics'],
      matchScore: 68,
      type: 'Remote',
      salary: '₹50,000/mo',
      logo: 'F',
      postedAt: '4 days ago',
    ),
  ];

  static const List<Map<String, dynamic>> dailyTasks = [
    {
      'title': 'Complete 1 Mock Interview',
      'subtitle': 'Behavioral — 15 min',
      'icon': 'mic',
      'done': true,
    },
    {
      'title': 'Practice English Writing',
      'subtitle': 'Grammar correction — 5 min',
      'icon': 'edit',
      'done': false,
    },
    {
      'title': 'Learn System Design Basics',
      'subtitle': 'Watch: Load Balancing',
      'icon': 'book',
      'done': false,
    },
    {
      'title': 'Update your resume skills',
      'subtitle': 'Add recent project',
      'icon': 'person',
      'done': false,
    },
  ];

  static const List<Map<String, dynamic>> skillGapData = [
    {'skill': 'Flutter', 'yours': 85, 'required': 90},
    {'skill': 'BLoC', 'yours': 50, 'required': 80},
    {'skill': 'REST APIs', 'yours': 75, 'required': 85},
    {'skill': 'Testing', 'yours': 30, 'required': 70},
    {'skill': 'CI/CD', 'yours': 20, 'required': 60},
    {'skill': 'System Design', 'yours': 25, 'required': 65},
  ];

  static const List<Map<String, String>> mockInterviewQuestions = [
    {
      'q': 'Tell me about yourself and your background in software development.',
      'type': 'Behavioral',
    },
    {
      'q': 'Describe a challenging project you worked on. What was your role and what did you learn?',
      'type': 'Behavioral',
    },
    {
      'q': 'Explain the difference between BLoC and Provider for state management in Flutter.',
      'type': 'Technical',
    },
    {
      'q': 'How would you design a URL shortening service like bit.ly?',
      'type': 'System Design',
    },
  ];

  static const List<Map<String, String>> englishCorrectionSamples = [
    {
      'original': 'I have did many projects in Flutter.',
      'corrected': 'I have done many projects in Flutter.',
      'tip': '✨ Use "have done" (present perfect), not "have did".',
    },
    {
      'original': 'She told me to goes to the meeting.',
      'corrected': 'She told me to go to the meeting.',
      'tip': '✨ After "to", use the base verb — "to go", not "to goes".',
    },
  ];
}

