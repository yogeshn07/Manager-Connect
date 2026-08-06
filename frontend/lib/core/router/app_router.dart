import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/shared/widgets/mc/mc_main_scaffold.dart';

import 'package:manager_connect/features/auth/presentation/screens/splash_screen.dart';
import 'package:manager_connect/features/auth/presentation/screens/welcome_screen.dart';
import 'package:manager_connect/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:manager_connect/features/auth/presentation/screens/create_profile_screen.dart';
import 'package:manager_connect/features/auth/presentation/screens/daily_gate_screen.dart';

import 'package:manager_connect/features/feed/presentation/screens/active_members_screen.dart';
import 'package:manager_connect/features/feed/presentation/screens/mc_feed_screen.dart';
import 'package:manager_connect/features/feed/presentation/screens/post_detail_screen.dart';

import 'package:manager_connect/features/events/presentation/screens/activities_list_screen.dart';
import 'package:manager_connect/features/events/presentation/screens/activity_detail_screen.dart';

import 'package:manager_connect/features/polls/presentation/screens/poll_detail_screen.dart';

import 'package:manager_connect/features/growth/presentation/screens/challenge_list_screen.dart';
import 'package:manager_connect/features/growth/presentation/screens/challenge_detail_screen.dart';

import 'package:manager_connect/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:manager_connect/features/analytics/presentation/screens/rankings_screen.dart';

import 'package:manager_connect/features/notifications/presentation/screens/notification_center_screen.dart';

import 'package:manager_connect/features/profile/presentation/screens/profile_screen.dart';
import 'package:manager_connect/features/profile/presentation/screens/member_profile_screen.dart';

import 'package:manager_connect/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:manager_connect/features/admin/presentation/screens/member_management_screen.dart';
import 'package:manager_connect/features/admin/presentation/screens/invitation_management_screen.dart';
import 'package:manager_connect/features/admin/presentation/screens/moderation_queue_screen.dart';
import 'package:manager_connect/features/admin/presentation/screens/attendance_recording_screen.dart';

import 'package:manager_connect/features/gi_news/presentation/screens/gi_news_feed_screen.dart';
import 'package:manager_connect/features/insights/presentation/screens/insight_detail_screen.dart';
import 'package:manager_connect/features/insights/presentation/screens/submit_insight_screen.dart';
import 'package:manager_connect/features/insights/presentation/screens/submission_history_screen.dart';
import 'package:manager_connect/features/insights/presentation/screens/review_queue_screen.dart';
import 'package:manager_connect/features/insights/presentation/screens/pipeline_health_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final List<RouteBase> appRoutes = [
  GoRoute(
    path: '/',
    builder: (context, state) => const SplashScreen(),
  ),

  GoRoute(
    path: RouteNames.welcome,
    builder: (context, state) => const WelcomeScreen(),
  ),
  GoRoute(
    path: RouteNames.verifyOtp,
    builder: (context, state) {
      final email = state.extra as String? ?? '';
      return VerifyOtpScreen(email: email);
    },
  ),
  GoRoute(
    path: RouteNames.createProfile,
    builder: (context, state) => const CreateProfileScreen(),
  ),
  GoRoute(
    path: RouteNames.gate,
    builder: (context, state) => const DailyGateScreen(),
  ),

  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (context, state, child) => MCMainScaffold(child: child),
    routes: [
      GoRoute(
        path: RouteNames.feed,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MCFeedScreen(),
        ),
        routes: [
          GoRoute(
            path: 'post/:id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final postId = state.pathParameters['id']!;
              return PostDetailScreen(postId: postId);
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.events,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ActivitiesListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'event/:id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final activityId = state.pathParameters['id']!;
              return ActivityDetailScreen(activityId: activityId);
            },
          ),
          GoRoute(
            path: 'poll/:id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final pollId = state.pathParameters['id']!;
              return PollDetailScreen(pollId: pollId);
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.growth,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ChallengeListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'challenge/:id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final challengeId = state.pathParameters['id']!;
              return ChallengeDetailScreen(challengeId: challengeId);
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.analytics,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AnalyticsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'rankings',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const RankingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.profile,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ProfileScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.insights,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: GINewsFeedScreen(),
        ),
        routes: [
          GoRoute(
            path: 'submit',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const SubmitInsightScreen(),
          ),
          GoRoute(
            path: 'history',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const SubmissionHistoryScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => InsightDetailScreen(
              insightId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  ),

  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.memberProfile,
    builder: (context, state) {
      final profileId = state.pathParameters['id']!;
      return MemberProfileScreen(profileId: profileId);
    },
  ),

  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.notifications,
    builder: (context, state) => const NotificationCenterScreen(),
  ),

  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.activeMembers,
    builder: (context, state) => const ActiveMembersScreen(),
  ),

  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.admin,
    builder: (context, state) => const AdminDashboardScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.adminInsightReview,
    builder: (context, state) => const ReviewQueueScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.adminInsightPipeline,
    builder: (context, state) => const PipelineHealthScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.adminMembers,
    builder: (context, state) => const MemberManagementScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/admin/invitations',
    builder: (context, state) => const InvitationManagementScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.adminFlagged,
    builder: (context, state) => const ModerationQueueScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.adminAttendance,
    builder: (context, state) => const AttendanceRecordingScreen(),
  ),

];
