import 'package:cloud_firestore/cloud_firestore.dart';

class ContestService {
  final _db = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> currentContestStream() async* {
    final settings = await _db.collection('settings').doc('global').get();
    final id = settings.data()?['currentContestId'] as String;
    yield* _db.collection('contests').doc(id).snapshots();
  }

  Future<String> currentContestId() async {
    final settings = await _db.collection('settings').doc('global').get();
    return settings.data()!['currentContestId'] as String;
  }

  Query<Map<String, dynamic>> myBetsQuery(String contestId, String uid) {
    return _db.collection('contests').doc(contestId)
        .collection('bets')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);
  }

  Query<Map<String, dynamic>> paidBetsQuery(String contestId) {
    return _db.collection('contests').doc(contestId).collection('bets')
        .where('statusPagamento', whereIn: ['paid','validated']);
  }
}
