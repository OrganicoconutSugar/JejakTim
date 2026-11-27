import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_screens.dart';
import '../features/projects/project_screens.dart';
import '../features/tasks/task_screens.dart';
import '../features/insights/insight_screens.dart';
import '../features/reports/report_screens.dart';
import '../features/profile/profile_screens.dart';
import 'controller.dart';
import 'design.dart';

GoRouter makeRouter(AppController controller) {
  GoRouter.optionURLReflectsImperativeAPIs = true;
  String? pendingInvite;
  GoRoute page(String path, Widget Function(GoRouterState) builder) => GoRoute(
    path: path,
    pageBuilder:
        (context, s) => CustomTransitionPage(
          key: s.pageKey,
          child: builder(s),
          transitionDuration: Duration(
            milliseconds: reduceMotion(context) ? 0 : 320,
          ),
          transitionsBuilder:
              (context, a, secondary, child) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              ),
        ),
  );
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: controller,
    redirect: (context, state) {
      if (state.uri.scheme == 'jejaktim' && state.uri.host == 'join') {
        final code = state.uri.pathSegments.firstOrNull?.trim().toUpperCase();
        if (code != null && RegExp(r'^[A-Za-z0-9-]{4,64}$').hasMatch(code)) {
          final target = '/projects/invite/$code/preview';
          if (!controller.authenticated) {
            pendingInvite = target;
            return '/auth/login';
          }
          return target;
        }
      }
      final path = state.uri.path;
      if (path == '/splash' || path == '/onboarding') return null;
      final auth = path.startsWith('/auth');
      if (!controller.authenticated && !auth) {
        if (RegExp(
          r'^/projects/invite/[A-Za-z0-9-]{4,64}/preview$',
        ).hasMatch(path)) {
          pendingInvite = path;
        }
        return '/auth/login';
      }
      if (controller.authenticated && auth) {
        final next = pendingInvite;
        pendingInvite = null;
        return next ?? '/home';
      }
      return null;
    },
    routes: [
      page('/splash', (_) => const SplashScreen()),
      page('/onboarding', (_) => const OnboardingScreen()),
      page(
        '/auth/:mode',
        (s) => AuthScreen(
          key: ValueKey(s.pathParameters['mode']),
          mode: s.pathParameters['mode']!,
        ),
      ),
      page('/home', (_) => const HomeScreen()),
      page('/notifications', (_) => const NotificationsScreen()),
      page('/projects', (_) => const ProjectsScreen()),
      page('/search', (_) => const ProjectsScreen()),
      page('/projects/new', (_) => const ProjectFormScreen()),
      page(
        '/projects/join',
        (s) => JoinScreen(initialCode: s.uri.queryParameters['code'] ?? ''),
      ),
      page(
        '/projects/invite/:code/preview',
        (s) => JoinScreen(initialCode: s.pathParameters['code']!),
      ),
      page(
        '/projects/:id/settings',
        (s) => ProjectFormScreen(projectId: s.pathParameters['id']!),
      ),
      page(
        '/projects/:id/tasks/new',
        (s) => TaskFormScreen(
          s.pathParameters['id']!,
          initialTitle: s.uri.queryParameters['title'],
          initialDescription: s.uri.queryParameters['desc'],
        ),
      ),
      for (final tab
          in {
            'tasks': 'Tugas',
            'members': 'Anggota',
            'activity': 'Aktivitas',
          }.entries)
        page(
          '/projects/:id/${tab.key}',
          (s) => ProjectDetailScreen(s.pathParameters['id']!, tab: tab.value),
        ),
      page(
        '/projects/:id',
        (s) => ProjectDetailScreen(s.pathParameters['id']!),
      ),
      page('/tasks', (_) => const TasksScreen()),
      page(
        '/tasks/:id/edit',
        (s) => TaskFormScreen(
          controller.task(s.pathParameters['id']!)?['projectId'] ?? '',
          taskId: s.pathParameters['id'],
        ),
      ),
      for (final action in ['update', 'evidence', 'review'])
        page(
          '/tasks/:id/$action',
          (s) => TaskActionScreen(s.pathParameters['id']!, action),
        ),
      page('/tasks/:id', (s) => TaskDetailScreen(s.pathParameters['id']!)),
      page('/insights', (_) => const InsightsScreen()),
      page(
        '/insights/:id',
        (s) => InsightsScreen(projectId: s.pathParameters['id']!),
      ),
      page('/reports/:id', (s) => ReportScreen(s.pathParameters['id']!)),
      page('/profile', (_) => const ProfileScreen()),
      page('/profile/edit', (_) => const ProfileEditScreen()),
      page('/profile/notifications', (_) => const PreferencesScreen()),
      page('/profile/privacy', (_) => const PrivacyScreen()),
      page('/profile/terms', (_) => const TermsScreen()),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: EmptyState(
            'Halaman tidak ditemukan',
            'Kembali ke ruang timmu.',
            action: FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Ke beranda'),
            ),
          ),
        ),
  );
}
