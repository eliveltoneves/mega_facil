import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Exports')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: db.collection('settings').doc('global').get(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final id = s.data!.data()?['currentContestId'] as String?;
          if (id == null) return const Center(child: Text('Nenhum concurso atual.'));
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: db.collection('contests').doc(id).get(),
            builder: (c2, s2) {
              final d = s2.data?.data() ?? {};
              final exports = (d['exports'] as Map?) ?? {};
              final betsCsv = exports['betsCsv'] as String?;
              final resultCsv = exports['resultCsv'] as String?;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (betsCsv != null) ListTile(title: const Text('Apostas CSV'), subtitle: Text(betsCsv)),
                  if (resultCsv != null) ListTile(title: const Text('Resultado CSV'), subtitle: Text(resultCsv)),
                  if (betsCsv == null && resultCsv == null)
                    const ListTile(title: Text('Nenhum export encontrado. Faça a apuração.')),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
