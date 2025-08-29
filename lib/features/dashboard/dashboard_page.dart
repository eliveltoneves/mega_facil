import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/contest_service.dart';
import '../../utils/time_utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _svc = ContestService();
  final _auth = FirebaseAuth.instance;

  int _paidCount = 0;
  int _preco = 2000;
  int _acumPrincipal = 0;
  int _acumEspecial = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _svc.currentContestStream(),
      builder: (ctx, snap) {
        // ⚠️ trate ERROS primeiro
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Minha Dashboard')),
            body: Center(
              child: Text('Erro ao carregar concurso atual:\n${snap.error}',
                  textAlign: TextAlign.center),
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snap.hasData || !snap.data!.exists || snap.data!.data() == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Minha Dashboard')),
            body: const Center(child: Text('Nenhum concurso ativo encontrado.')),
          );
        }

        final contest = snap.data!;
        final data = contest.data()!;
        final id = contest.id;

        // Campos defensivos
        final tsFech = data['fechamento'];
        final status = (data['status'] as String?) ?? 'closed';
        final fechamento = (tsFech is Timestamp) ? tsFech.toDate() : DateTime.now();
        final aberto = DateTime.now().isBefore(fechamento) && status == 'open';

        _preco = (data['precoApostaCentavos'] as int?) ?? 2000;
        _acumPrincipal = (data['acumuladoPrincipalCentavos'] as int?) ?? 0;
        _acumEspecial  = (data['acumuladoEspecialCentavos']  as int?) ?? 0;

        return Scaffold(
          appBar: AppBar(title: const Text('Minha Dashboard')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Concurso Interno #${data['numeroInterno'] ?? '-'}',
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text('Ref. Mega-Sena #${data['refMegasena'] ?? '-'}',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 8),
                              Text('Fecha em: ${TimeUtils.fmtDate(fechamento)}'),
                              const SizedBox(height: 4),
                              Text(
                                'Tempo restante: ${TimeUtils.remainingStr(DateTime.now(), fechamento)}',
                                style: TextStyle(color: aberto ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AcumuladosCard(
                        contestId: id,
                        preco: _preco,
                        onPaidCount: (c) {
                          // Evite setState dentro do build: poste para o próximo frame
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _paidCount = c);
                          });
                        },
                        acumPrincipal: _acumPrincipal,
                        acumEspecial: _acumEspecial,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (data['resultado'] != null && data['resultado']['n1'] != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        children: [
                          Text('Resultado (último):',
                              style: Theme.of(context).textTheme.titleMedium),
                          for (final k in ['n1','n2','n3','n4','n5','n6'])
                            _ball((data['resultado'][k] as int?) ?? 0),
                          if (data['resultado']['data'] != null &&
                              data['resultado']['data'] is Timestamp)
                            Text(' • ${TimeUtils.fmtDate((data['resultado']['data'] as Timestamp).toDate())}'),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: aberto ? () => context.push('/nova-aposta') : null,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Fazer Aposta'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: aberto ? () => context.push('/repetir-aposta') : null,
                      icon: const Icon(Icons.history),
                      label: const Text('Repetir Aposta'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _svc.myBetsQuery(id, _auth.currentUser!.uid).snapshots(),
                    builder: (ctx, betsSnap) {
                      if (betsSnap.hasError) {
                        return Center(child: Text('Erro ao carregar suas apostas:\n${betsSnap.error}'));
                      }
                      if (betsSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = betsSnap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('Você ainda não fez apostas neste concurso.'));
                      }
                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final b = docs[i].data();
                          return Card(
                            child: ListTile(
                              title: Text('Aposta ${docs[i].id} • ${b['origem'] ?? '-'}'),
                              subtitle: Text('Concurso #${data['numeroInterno'] ?? '-'} • Mega-Sena #${data['refMegasena'] ?? '-'}'),
                              trailing: Chip(label: Text((b['statusPagamento'] ?? '—').toString())),
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

  Widget _ball(int n) => Container(
    width: 36, height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
        color: Colors.green.shade600, shape: BoxShape.circle),
    child: Text(n.toString().padLeft(2,'0'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  );


class _AcumuladosCard extends StatelessWidget {
  final String contestId;
  final int preco;
  final int acumPrincipal;
  final int acumEspecial;
  final ValueChanged<int> onPaidCount;

  const _AcumuladosCard({
    super.key,
    required this.contestId,
    required this.preco,
    required this.onPaidCount,
    required this.acumPrincipal,
    required this.acumEspecial,
  });

  @override
  Widget build(BuildContext context) {
    final svc = ContestService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.paidBetsQuery(contestId).snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erro ao carregar acumulados:\n${snap.error}'),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final paid = snap.data?.docs.length ?? 0;

        // Evite setState no meio do build do filho
        WidgetsBinding.instance.addPostFrameCallback((_) => onPaidCount(paid));

        final arrecadacao = paid * preco;
        final principal = (arrecadacao * 0.70).round() + acumPrincipal;
        final peFrio    = (arrecadacao * 0.05).round();
        final virada    = (arrecadacao * 0.05).round() + acumEspecial;

        String moeda(int cents) => 'R\$ ${(cents/100).toStringAsFixed(2)}';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acumulatórios (parciais)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('Apostas pagas: $paid'),
                Text('Arrecadação: ${moeda(arrecadacao)}'),
                const Divider(),
                Text('Prêmio Principal (70% + carry): ${moeda(principal)}'),
                Text('Prêmio Pé Frio (5%): ${moeda(peFrio)}'),
                Text('Mega da Virada (5% + carry): ${moeda(virada)}'),
              ],
            ),
          ),
        );
      },
    );
  }
}


