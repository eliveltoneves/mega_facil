import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContestService {
  final _db = FirebaseFirestore.instance;

  /// Stream do concurso atual (defensiva se settings/global não tiver id).
  Stream<DocumentSnapshot<Map<String, dynamic>>?> currentContestStream() async* {
    final settingsSnap = await _db.collection('settings').doc('global').get();
    final id = settingsSnap.data()?['currentContestId'] as String?;
    if (id == null || id.isEmpty) {
      yield null;
      return;
    }
    yield* _db.collection('contests').doc(id).snapshots();
  }

  Future<String?> currentContestId() async {
    final settings = await _db.collection('settings').doc('global').get();
    return settings.data()?['currentContestId'] as String?;
  }

  /// Apostas do usuário no concurso (para telas específicas).
  Query<Map<String, dynamic>> myBetsQuery(String contestId, String uid) {
    return _db
        .collection('contests')
        .doc(contestId)
        .collection('bets')
        .where('userId', isEqualTo: uid);
  }

  /// **Todas** as apostas do concurso (sem orderBy para evitar índice).
  Query<Map<String, dynamic>> allBetsQuery(String contestId) {
    return _db
        .collection('contests')
        .doc(contestId)
        .collection('bets');
  }

  /// Contagem das apostas do usuário no concurso (para "x/5").
  Future<int> userBetsCountInContest(String contestId, String uid) async {
    final q = await _db
        .collection('contests')
        .doc(contestId)
        .collection('bets')
        .where('userId', isEqualTo: uid)
        .get();
    return q.size;
  }

  /// Nome do usuário (cache simples).
  final Map<String, String> _userNameCache = {};
  Future<String> getUserName(String uid) async {
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    final snap = await _db.collection('users').doc(uid).get();
    final name = (snap.data()?['nome'] as String?)?.trim();
    final result = (name == null || name.isEmpty) ? uid : name;
    _userNameCache[uid] = result;
    return result;
  }
}
