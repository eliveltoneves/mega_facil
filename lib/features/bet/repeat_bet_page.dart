import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/contest_service.dart';

class RepeatBetPage extends StatefulWidget {
  const RepeatBetPage({super.key});
  @override
  State<RepeatBetPage> createState() => _RepeatBetPageState();
}

class _RepeatBetPageState extends State<RepeatBetPage> {
  final _svc = ContestService();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _error;
  bool _saving = false;

  String _hash(List<int> nums) {
    final sorted = [...nums]..sort();
    return sorted.join(',');
    // (mesmo formato usado no backend)
  }

  Future<void> _repetir(List<int> numeros) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final contestId = await _svc.currentContestId();
      if (contestId == null) {
        setState(() => _error = 'Nenhum concurso ativo.');
        return;
      }
      final betCol =
      _db.collection('contests').doc(contestId).collection('bets');

      // Limite 5
      final my = await betCol
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .get();
      if (my.size >= 5) {
        setState(() => _error = 'Limite de 5 apostas por concurso atingido.');
        return;
      }

      // Duplicidade (cliente): evita salvar se já existir a mesma combinação
      final h = _hash(numeros);
      final dup = await betCol
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .where('hash25', isEqualTo: h)
          .limit(1)
          .get();
      if (dup.size > 0) {
        setState(() => _error = 'Você já possui uma aposta com esses 25 números neste concurso.');
        return;
      }

      await betCol.add({
        'userId': _auth.currentUser!.uid,
        'numeros': (numeros..sort()),
        'hash25': h,
        'statusPagamento': 'pending',
        'origem': 'repetida',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aposta repetida criada.')),
        );
        context.go('/dashboard');
      }
    } catch (_) {
      setState(() => _error = 'Falha ao repetir aposta.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _svc.currentContestId(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final currentId = snap.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Repetir Aposta')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _db
                        .collectionGroup('bets')
                        .where('userId', isEqualTo: _auth.currentUser!.uid)
                        .orderBy('createdAt', descending: true)
                        .limit(50)
                        .snapshots(),
                    builder: (ctx, s) {
                      if (!s.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = s.data!.docs
                          .where((d) => !d.reference.path
                          .contains('/contests/$currentId/bets/'))
                          .toList();
                      if (items.isEmpty) {
                        return const Center(
                          child: Text('Você não possui apostas anteriores.'),
                        );
                      }
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final b = items[i].data();
                          final nums = (b['numeros'] as List).cast<int>();
                          return Card(
                            child: ListTile(
                              title: Wrap(
                                spacing: 6,
                                children: nums
                                    .map((n) => Chip(
                                    label:
                                    Text(n.toString().padLeft(2, '0'))))
                                    .toList(),
                              ),
                              subtitle: Text(
                                  'Status: ${b['statusPagamento']} • Origem: ${b['origem']}'),
                              trailing: ElevatedButton(
                                onPressed:
                                _saving ? null : () => _repetir(nums),
                                child: const Text('Repetir'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
