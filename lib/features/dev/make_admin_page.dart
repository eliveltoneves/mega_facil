import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MakeAdminPage extends StatefulWidget {
  const MakeAdminPage({super.key});
  @override
  State<MakeAdminPage> createState() => _MakeAdminPageState();
}

class _MakeAdminPageState extends State<MakeAdminPage> {
  final _uidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // por conveniência, preenche com seu próprio UID (promover a si mesmo)
    _uidCtrl.text = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEV • Tornar Admin')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Apenas usuários na whitelist do Cloud Function podem promover.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _uidCtrl,
              decoration: const InputDecoration(
                labelText: 'UID para promover (admin)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                try {
                  final me = FirebaseAuth.instance.currentUser;
                  if (me == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Faça login primeiro.')),
                    );
                    return;
                  }
                  final fx = FirebaseFunctions.instanceFor(
                    region: 'southamerica-east1',
                  );
                  final callable = fx.httpsCallable('makeAdmin');
                  final resp = await callable.call({'uid': _uidCtrl.text.trim()});
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('OK: ${resp.data}')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Falha: $e')),
                  );
                }
              },
              child: const Text('Promover'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // força refresh do token local para refletir claims recém-aplicadas
                try {
                  await FirebaseAuth.instance.currentUser?.getIdToken(true);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token atualizado')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar token: $e')),
                  );
                }
              },
              child: const Text('Atualizar token local'),
            ),
          ],
        ),
      ),
    );
  }
}
