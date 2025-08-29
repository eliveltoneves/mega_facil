import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/contest_service.dart';
import 'widgets/number_grid.dart';

class NewBetPage extends StatefulWidget {
  const NewBetPage({super.key});
  @override
  State<NewBetPage> createState() => _NewBetPageState();
}

class _NewBetPageState extends State<NewBetPage> {
  final _svc = ContestService();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Set<int> _nums = {};
  bool _saving = false;
  String? _error;

  Future<void> _salvar() async {
    if (_nums.length != 25) { setState(() => _error = 'Selecione exatamente 25 números.'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      final contestId = await _svc.currentContestId();
      final betRef = _db.collection('contests').doc(contestId).collection('bets');
      // valida limite 5 (cliente)
      final my = await betRef.where('userId', isEqualTo: _auth.currentUser!.uid).get();
      if (my.size >= 5) { setState(() => _error = 'Limite de 5 apostas por concurso atingido.'); return; }

      final numeros = _nums.toList()..sort();
      await betRef.add({
        'userId': _auth.currentUser!.uid,
        'numeros': numeros,
        'statusPagamento': 'pending',
        'origem': 'nova',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aposta criada. Realize o pagamento para confirmação.')));
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _error = 'Falha ao salvar aposta.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Aposta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            Text('Escolha 25 números (01–60)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            NumberGrid(initial: const {}, max: 25, onChanged: (s) => _nums = s),
            const SizedBox(height: 12),
            Text('Pagamento: R\$ 20,00 • Chave Pix: marlonjordao21@gmail.com\n'
                'Após o pagamento, o status muda para “paid/validated” pelo admin.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _saving ? null : _salvar, child: Text(_saving ? 'Salvando...' : 'Confirmar Aposta')),
          ],
        ),
      ),
    );
  }
}
