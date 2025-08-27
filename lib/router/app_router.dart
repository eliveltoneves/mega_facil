import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/auth/terms_page.dart';
import '../features/profile/profile_page.dart';
import '../core/auth_notifier.dart'; // <-- o arquivo acima

class AppRouter {
  static final _auth = FirebaseAuth.instance;

  // mantenha uma instância viva do notifier
  static final _authNotifier = AuthStateNotifier();

  static final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _authNotifier,
    redirect: (ctx, state) {
      final loggedIn = _auth.currentUser != null;

      // para versões diferentes do go_router:
      final location = state.matchedLocation; // se der erro, troque por: state.subloc

      final loggingIn = location == '/login' ||
          location == '/register' ||
          location == '/termos';

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && (location == '/login' || location == '/register')) {
        return '/perfil';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
      GoRoute(path: '/termos', builder: (c, s) => const TermsPage()),
      GoRoute(path: '/perfil', builder: (c, s) => const ProfilePage()),
    ],
  );
}
