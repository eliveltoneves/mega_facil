import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AdminStatus { unknown, user, admin }

class AuthStateNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _sub;

  bool _loggedIn = false;
  AdminStatus _adminStatus = AdminStatus.unknown;
  String? _lastUidRefreshed;

  bool get loggedIn => _loggedIn;
  AdminStatus get adminStatus => _adminStatus;
  bool get ready => !_loggedIn || _adminStatus != AdminStatus.unknown;

  AuthStateNotifier() {
    _sub = _auth.idTokenChanges().listen((user) async {
      _loggedIn = user != null;

      if (user == null) {
        _adminStatus = AdminStatus.unknown;
        _lastUidRefreshed = null;
        notifyListeners();
        return;
      }

      // Força um refresh de token 1x por UID para puxar claims atualizadas
      try {
        if (_lastUidRefreshed != user.uid) {
          await user.getIdToken(true);
          _lastUidRefreshed = user.uid;
        }
      } catch (_) {}

      try {
        final res = await user.getIdTokenResult();
        _adminStatus =
        (res.claims?['admin'] == true) ? AdminStatus.admin : AdminStatus.user;
      } catch (_) {
        _adminStatus = AdminStatus.user;
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
