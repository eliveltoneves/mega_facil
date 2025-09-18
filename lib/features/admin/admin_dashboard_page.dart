import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/top_menu.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin • Mega Fácil'),
        actions: const [TopMenu(showProfile: true)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ações principais
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => context.push('/admin/concurso'),
                  child: const Text('Criar concurso'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.push('/admin/concurso'),
                  child: const Text('Gerenciar concurso'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de concursos
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: db
                    .collection('contests')
                    .orderBy('abertura', descending: true)
                    .snapshots(),
                builder: (c, s) {
                  if (s.hasError) {
                    return Center(child: Text('Erro: ${s.error}'));
                  }
                  if (!s.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = s.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('Nenhum concurso criado ainda.'));
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final data = d.data();
                      final numero = data['numeroInterno'] ?? '-';
                      final ref = data['refMegasena'] ?? '-';
                      final status = (data['status'] ?? 'closed').toString();
                      final fechado = status != 'open';
                      final label = fechado ? 'Fechado' : 'Ativo';
                      final color =
                      fechado ? Colors.grey.shade600 : Colors.green.shade700;

                      return Card(
                        child: ListTile(
                          title: Text('Concurso interno #$numero'),
                          subtitle: Text('Ref. Mega-Sena #$ref'),
                          trailing: Chip(
                            label: Text(label),
                            backgroundColor: color.withValues(alpha: 0.1),
                            labelStyle: TextStyle(color: color),
                          ),
                          onTap: () => context.push('/admin/concurso'),
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
  }
}
