import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/next_saturday.dart';

class ManageContestPage extends StatefulWidget {
  const ManageContestPage({super.key});
  @override
  State<ManageContestPage> createState() => _ManageContestPageState();
}

class _ManageContestPageState extends State<ManageContestPage> {
  final _db = FirebaseFirestore.instance;
  final _numeroInterno = TextEditingController();
  final _refMega = TextEditingController();

  Future<void> _openContest() async {
    final now = DateTime.now();
    final fechamento = saturdayNoonBRT(now.toUtc());
    final doc = _db.collection('contests').doc(); // contestId autogerado; pode usar sequência própria
    await doc.set({
      'numeroInterno': int.tryParse(_numeroInterno.text),
      'refMegasena': int.tryParse(_refMega.text),
      'status': 'open',
      'abertura': FieldValue.serverTimestamp(),
      'fechamento': Timestamp.fromDate(fechamento),
      'precoApostaCentavos': 2000,
      'acumuladoPrincipalCentavos': 0,
      'acumuladoEspecialCentavos': 0,
    });
    await _db.collection('settings').doc('global').set({
      'currentContestId': doc.id,
      'previousContestId': FieldValue.delete(),
      'precoApostaCentavos': 2000,
      'rateios': {'principal': 0.70, 'peFrio': 0.05, 'especial': 0.05, 'taxa': 0.20},
    }, SetOptions(merge: true));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Concurso aberto.')));
  }

  Future<void> _closeContest(String contestId) async {
    await _db.collection('contests').doc(contestId).update({'status': 'closed'});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Concurso fechado.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Concurso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _db.collection('settings').doc('global').get(),
          builder: (c, s) {
            final g = s.data?.data() ?? {};
            final current = g['currentContestId'] as String?;
            return ListView(
              children: [
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Abrir novo concurso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(controller: _numeroInterno, decoration: const InputDecoration(labelText: 'Número interno')),
                      const SizedBox(height: 8),
                      TextField(controller: _refMega, decoration: const InputDecoration(labelText: 'Ref. Mega-Sena')),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _openContest, child: const Text('Abrir')),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                if (current != null) Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: _db.collection('contests').doc(current).get(),
                      builder: (c2, s2) {
                        final d = s2.data?.data();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Atual: $current (${d?['status'] ?? '-'})'),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: () => _closeContest(current), child: const Text('Fechar')),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
