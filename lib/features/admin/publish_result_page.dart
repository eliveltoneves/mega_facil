import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublishResultPage extends StatefulWidget {
  const PublishResultPage({super.key});
  @override
  State<PublishResultPage> createState() => _PublishResultPageState();
}

class _PublishResultPageState extends State<PublishResultPage> {
  final _n = List.generate(6, (_) => TextEditingController());
  bool _loading = false;
  String? _msg;

  Future<void> _apurar() async {
    setState(() { _loading = true; _msg = null; });
    try {
      final g = await FirebaseFirestore.instance.collection('settings').doc('global').get();
      final contestId = g.data()?['currentContestId'] as String;
      final callable = FirebaseFunctions.instance.httpsCallable('settleContest');
      final res = await callable.call({
        'contestId': contestId,
        'n1': int.parse(_n[0].text),
        'n2': int.parse(_n[1].text),
        'n3': int.parse(_n[2].text),
        'n4': int.parse(_n[3].text),
        'n5': int.parse(_n[4].text),
        'n6': int.parse(_n[5].text),
      });
      setState(() => _msg = 'Apuração concluída. Exports: ${res.data['exports']}');
    } catch (e) {
      setState(() => _msg = 'Erro: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar Resultado & Apurar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(spacing: 8, children: List.generate(6, (i) =>
                SizedBox(width: 80, child: TextField(controller: _n[i], keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'N${i+1}')))
            )),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loading ? null : _apurar, child: Text(_loading ? 'Processando...' : 'Apurar & Gerar Planilhas')),
            const SizedBox(height: 12),
            if (_msg != null) Text(_msg!),
          ],
        ),
      ),
    );
  }
}
