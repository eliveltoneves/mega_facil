import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/admin/admin_dashboard_page.dart';
import '../features/admin/export_page.dart';
import '../features/admin/manage_contest_page.dart';
import '../features/admin/publish_result_page.dart';
import '../features/auth/auth_loading_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/auth/terms_page.dart';
import '../features/bet/new_bet_page.dart';
import '../features/bet/repeat_bet_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/dev/make_admin_page.dart';
import '../features/profile/profile_page.dart';
import '../features/auth/forgot_password_page.dart';
import '../core/auth_notifier.dart';

class AppRouter {
  static final _auth = FirebaseAuth.instance;
  static final _authNotifier = AuthStateNotifier();

  static final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _authNotifier,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Erro de rota')),
      body: Center(child: Text(state.error?.toString() ?? 'Rota não encontrada')),
    ),
    redirect: (ctx, state) {
      final loc = state.matchedLocation;
      final loggedIn = _authNotifier.loggedIn;
      final status = _authNotifier.adminStatus;
      final ready = _authNotifier.ready;

      final isAuthPage = {'/login', '/register', '/termos'}.contains(loc);

      // Não logado: só pode estar em páginas de auth
      if (!loggedIn && !isAuthPage) return '/login';

      // Logado, mas claims ainda não carregadas → vá para splash
      if (loggedIn && !ready && loc != '/auth-loading') return '/auth-loading';

      // Pós-login saindo das telas de auth → decida destino
      if (loggedIn && ready && (loc == '/login' || loc == '/register')) {
        return status == AdminStatus.admin ? '/admin' : '/dashboard';
      }

      // Protege /admin
      if (loggedIn && ready && loc == '/admin' && status != AdminStatus.admin) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/auth-loading', builder: (c, s) => const AuthLoadingPage()),
      GoRoute(path: '/dev/make-admin', builder: (c, s) => const MakeAdminPage()),
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
      GoRoute(path: '/esqueci-senha', builder: (c, s) => const ForgotPasswordPage()),
      GoRoute(path: '/termos', builder: (c, s) => const TermsPage()),
      GoRoute(path: '/perfil', builder: (c, s) => const ProfilePage()),
      GoRoute(path: '/dashboard', builder: (c, s) => const DashboardPage()),
      GoRoute(path: '/nova-aposta', builder: (c, s) => const NewBetPage()),
      GoRoute(path: '/repetir-aposta', builder: (c, s) => const RepeatBetPage()),
      GoRoute(path: '/admin', builder: (c, s) => const AdminDashboardPage()),
      GoRoute(path: '/admin/concurso', builder: (c, s) => const ManageContestPage()),
      GoRoute(path: '/admin/resultado', builder: (c, s) => const PublishResultPage()),
      GoRoute(path: '/admin/export', builder: (c, s) => const ExportPage()),
    ],
  );
}
