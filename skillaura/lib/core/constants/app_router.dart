import 'package:go_router/go_router.dart';

import '../../domain/entities/job.dart';
import '../../presentation/pages/auth/login_screen.dart';
import '../../presentation/pages/auth/register_screen.dart';
import '../../presentation/pages/dashboard/dashboard_screen.dart';
import '../../presentation/pages/interview/english_practice_screen.dart';
import '../../presentation/pages/interview/interview_hub_screen.dart';
import '../../presentation/pages/interview/coding_prep_screen.dart';
import '../../presentation/pages/interview/company_questions_screen.dart';
import '../../presentation/pages/interview/coding_ide_screen.dart';
import '../../presentation/pages/interview/aptitude_screen.dart';
import '../../presentation/pages/interview/aptitude_test_screen.dart';
import '../../presentation/pages/interview/mock_test_screen.dart';
import '../../presentation/pages/interview/mock_test_exam_screen.dart';
import '../../presentation/pages/interview/mock_interview_chat_screen.dart';
import '../../presentation/pages/jobs/job_detail_screen.dart';
import '../../presentation/pages/jobs/jobs_screen.dart';
import '../../presentation/pages/onboarding/onboarding_screen.dart';
import '../../presentation/pages/onboarding/splash_screen.dart';
import '../../presentation/pages/profile/profile_screen.dart';
import '../../presentation/pages/shell/main_shell.dart';
import '../constants/app_constants.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.routeSplash,
  routes: [
    GoRoute(
      path: AppConstants.routeSplash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppConstants.routeOnboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppConstants.routeLogin,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.routeRegister,
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/${AppConstants.routeDashboard}',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/${AppConstants.routeJobs}',
          builder: (context, state) => const JobsScreen(),
          routes: [
            GoRoute(
              path: AppConstants.routeJobDetail,
              builder: (context, state) {
                final job = state.extra as Job;
                return JobDetailScreen(job: job);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/${AppConstants.routeInterviewHub}',
          builder: (context, state) => const InterviewHubScreen(),
          routes: [
            GoRoute(
              path: AppConstants.routeEnglishPractice,
              builder: (context, state) => const EnglishPracticeScreen(),
            ),
            GoRoute(
              path: AppConstants.routeMockInterview,
              builder: (context, state) => const MockInterviewChatScreen(),
            ),
            // Coding Prep module
            GoRoute(
              path: AppConstants.routeCodingPrep,
              builder: (context, state) => const CodingPrepScreen(),
              routes: [
                GoRoute(
                  path: AppConstants.routeCompanyQuestions,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>;
                    return CompanyQuestionsScreen(
                      companyId: extra['companyId'] as String,
                      companyName: extra['companyName'] as String,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: AppConstants.routeCodingIDE,
                      builder: (context, state) {
                        final extra = state.extra as Map<String, dynamic>;
                        return CodingIDEScreen(
                          questionId: extra['questionId'] as String,
                          questionTitle: extra['questionTitle'] as String,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Aptitude module
            GoRoute(
              path: AppConstants.routeAptitude,
              builder: (context, state) => const AptitudeScreen(),
              routes: [
                GoRoute(
                  path: AppConstants.routeAptitudeTest,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>;
                    return AptitudeTestScreen(
                      categoryId: extra['categoryId'] as String,
                      categoryName: extra['categoryName'] as String,
                    );
                  },
                ),
              ],
            ),
            // Mock Test module
            GoRoute(
              path: AppConstants.routeMockTest,
              builder: (context, state) => const MockTestScreen(),
              routes: [
                GoRoute(
                  path: AppConstants.routeMockTestExam,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>;
                    return MockTestExamScreen(
                      domainId: extra['domainId'] as String,
                      domainName: extra['domainName'] as String,
                      durationMinutes: extra['duration'] as int,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/${AppConstants.routeProfile}',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
