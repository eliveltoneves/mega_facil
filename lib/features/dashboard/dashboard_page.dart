import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../services/contest_service.dart';
import '../../utils/time_utils.dart';
import '../../widgets/top_menu.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _svc = ContestService();

  static const int betPriceCents = 2000;      // R$ 20,00
  static const int viradaBaseCents = 1310000; // R$ 13.100,00

  String _moeda(int cents) =>
      'R\$ ${(cents / 100).toStringAsFixed(2)}'.replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      stream: _svc.currentContestStream(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('MEGA FÁCIL'), actions: const [TopMenu()]),
            body: Center(child: Text('Erro ao carregar concurso atual:\n${snap.error}')),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final contestSnap = snap.data;
        if (contestSnap == null || !contestSnap.exists || contestSnap.data() == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('MEGA FÁCIL'), actions: const [TopMenu()]),
            body: const Center(child: Text('Nenhum concurso ativo encontrado.')),
          );
        }
        final cdata = contestSnap.data()!;
        final contestId = contestSnap.id;

        final tsFech = cdata['fechamento'];
        final status = (cdata['status'] as String?) ?? 'closed';
        final fechamento =
        (tsFech is Timestamp) ? tsFech.toDate() : DateTime.now();

        final numeroInterno = cdata['numeroInterno']?.toString() ?? '-';
        final refMegaSena = cdata['refMegasena']?.toString() ?? '-';
        final carryAnterior = (cdata['acumuladoPrincipalCentavos'] as int?) ?? 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _svc.allBetsQuery(contestId).snapshots(),
          builder: (context, betsSnap) {
            if (betsSnap.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('MEGA FÁCIL'), actions: const [TopMenu()]),
                body: Center(child: Text('Erro ao carregar apostas:\n${betsSnap.error}')),
              );
            }
            if (betsSnap.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: const Text('MEGA FÁCIL'), actions: const [TopMenu()]),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final raw = betsSnap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            // --------- Numeração por usuário (1/5, 2/5, ... na ordem de criação) ----------
            DateTime _toDate(dynamic v) =>
                (v is Timestamp) ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

            final asc = [...raw]..sort((a, b) {
              final da = _toDate(a.data()['createdAt']);
              final db = _toDate(b.data()['createdAt']);
              return da.compareTo(db);
            });

            final Map<String, int> perUserCounter = {};
            final Map<String, int> betPosition = {}; // doc.id -> posição do usuário
            for (final d in asc) {
              final uid = (d.data()['userId'] ?? '') as String;
              perUserCounter[uid] = (perUserCounter[uid] ?? 0) + 1;
              betPosition[d.id] = perUserCounter[uid]!;
            }

            // Lista final para exibir (DESC por createdAt)
            final docs = asc.reversed.toList();

            final totalApostas = docs.length;
            final valorArrecadado = totalApostas * betPriceCents;
            final premioPrincipal = (valorArrecadado * 0.70).round();
            final premioPeFrio    = (valorArrecadado * 0.05).round();
            final megaVirada      = viradaBaseCents + (valorArrecadado * 0.05).round();

            return Scaffold(
              appBar: AppBar(title: const Text('MEGA FÁCIL'), actions: const [TopMenu()]),
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _infoRow(children: [
                      _pill('Concurso', numeroInterno),
                      _pill('Ref. Sorteio', refMegaSena),
                      _pill('Apostas Realizadas', totalApostas.toString()),
                      _pill('Data Sorteio', TimeUtils.fmtDate(fechamento).toUpperCase()),
                    ]),
                    const SizedBox(height: 8),
                    _infoRow(children: [
                      _pill('Valor Arrecadado', _moeda(valorArrecadado)),
                      _pill('Prêmio Acumulado de Sorteios Anteriores', _moeda(carryAnterior)),
                      _pill('Mega Fácil da Virada', _moeda(megaVirada)),
                    ]),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            title:
                            'Prêmio Principal (06 acertos)\npara ${TimeUtils.fmtDate(fechamento).toUpperCase()}',
                            value: _moeda(premioPrincipal),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _metricCard(
                            title:
                            'Prêmio Pé Frio (0 acertos)\npara ${TimeUtils.fmtDate(fechamento).toUpperCase()}',
                            value: _moeda(premioPeFrio),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 220,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            ),
                            onPressed: status == 'open' ? () => context.push('/nova-aposta') : null,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Fazer Aposta'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ================== TABELA ==================
                    // Cabeçalho fixo (destacado)
                    _betsHeaderBar(),
                    // Corpo rolável (apenas linhas, com zebra)
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.only(top: 6),
                        clipBehavior: Clip.antiAlias,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final tableWidth = constraints.maxWidth;
                            if (docs.isEmpty) {
                              return const Center(child: Text('Nenhuma aposta registrada ainda.'));
                            }
                            return Scrollbar(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: tableWidth),
                                    child: DataTable(
                                      // escondemos o header nativo para manter o nosso header fixo
                                      headingRowHeight: 0,
                                      columnSpacing: 24,
                                      columns: const [
                                        DataColumn(label: SizedBox()), // N°
                                        DataColumn(label: SizedBox()), // Data
                                        DataColumn(label: SizedBox()), // Hora
                                        DataColumn(label: SizedBox()), // Nome
                                        DataColumn(label: SizedBox()), // Qtd
                                        DataColumn(label: SizedBox()), // ID
                                        DataColumn(label: SizedBox()), // Bilhete
                                      ],
                                      rows: [
                                        for (int i = 0; i < docs.length; i++)
                                          _betRow(
                                            context: context,
                                            index: totalApostas - i, // N° decrescente
                                            doc: docs[i],
                                            position: betPosition[docs[i].id] ?? 1,
                                            contestId: contestId,
                                            concursoLabel: numeroInterno,
                                            refLabel: refMegaSena,
                                            fechamento: fechamento,
                                            // zebra
                                            color: MaterialStateProperty.resolveWith<Color?>(
                                                  (_) => (i % 2 == 0)
                                                  ? Colors.green.shade50
                                                  : Colors.green.shade50.withOpacity(0.35),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------- Widgets auxiliares ----------

  Widget _infoRow({required List<Widget> children}) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 8),
        ]
      ],
    );
  }

  Widget _pill(String title, String value) {
    final base = Colors.green.shade700;
    final bg = base.withAlpha((0.08 * 255).round());
    final border = base.withAlpha((0.30 * 255).round());
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _metricCard({required String title, required String value}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Cabeçalho fixo da tabela
  Widget _betsHeaderBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          _HeaderCell('N°', flex: 1),
          _HeaderCell('Data', flex: 2),
          _HeaderCell('Hora', flex: 2),
          _HeaderCell('Nome', flex: 5),
          _HeaderCell('Qtd de apostas', flex: 3),
          _HeaderCell('ID da Aposta', flex: 6),
          _HeaderCell('Bilhete', flex: 2, center: true),
        ],
      ),
    );
  }

  DataRow _betRow({
    required BuildContext context,
    required int index,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required int position, // 1..5 do usuário
    required String contestId,
    required String concursoLabel,
    required String refLabel,
    required DateTime fechamento,
    MaterialStateProperty<Color?>? color,
  }) {
    final data = doc.data();
    final ts = data['createdAt'];
    final dt = (ts is Timestamp) ? ts.toDate() : DateTime.now();
    final uid = (data['userId'] ?? '') as String;

    final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final numeros = ((data['numeros'] as List?) ?? const [])
        .map((e) => int.tryParse(e.toString()) ?? 0)
        .toList()
      ..sort();

    return DataRow(
      color: color,
      cells: [
        DataCell(Text(index.toString())),
        DataCell(Text(dateStr)),
        DataCell(Text(timeStr)),
        // Nome de QUALQUER usuário
        DataCell(FutureBuilder<String>(
          future: _svc.getUserName(uid),
          builder: (c, s) => Text(s.data ?? '...'),
        )),
        DataCell(Text('$position/5')),
        DataCell(SelectableText(doc.id)),
        DataCell(IconButton(
          tooltip: 'Conferir bilhete',
          icon: const Icon(Icons.receipt_long),
          onPressed: () {
            _showTicket(
              context: context,
              concurso: concursoLabel,
              refSorteio: refLabel,
              data: dateStr,
              hora: timeStr,
              userId: uid,
              posicao: position,
              apostaId: doc.id,
              codPagamento: '—', // placeholder até integrar pagamento
              numeros: numeros,
              fechamento: fechamento,
            );
          },
        )),
      ],
    );
  }

  // ---------- Dialog do Bilhete ----------
  Future<void> _showTicket({
    required BuildContext context,
    required String concurso,
    required String refSorteio,
    required String data,
    required String hora,
    required String userId,
    required int posicao,
    required String apostaId,
    required String codPagamento,
    required List<int> numeros,
    required DateTime fechamento,
  }) async {
    final nomeFuture = _svc.getUserName(userId);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.green, size: 28),
                      const SizedBox(width: 8),
                      const Text('Bilhete de Aposta',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Fechar',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey.shade300, height: 1),

                  const SizedBox(height: 12),
                  _ticketRow('Concurso', concurso),
                  _ticketRow('Ref. Sorteio', refSorteio),
                  _ticketRow('Data', data),
                  _ticketRow('Hora', hora),
                  FutureBuilder<String>(
                    future: nomeFuture,
                    builder: (c, s) => _ticketRow('Nome', s.data ?? '...'),
                  ),
                  _ticketRow('Nº da aposta', '$posicao/5'),
                  _ticketRow('ID da aposta', apostaId, selectable: true),
                  _ticketRow('Cód. Pagamento', codPagamento),

                  const SizedBox(height: 14),
                  Text('Números',
                      style: TextStyle(
                          color: Colors.green.shade900, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    children: [
                      for (final n in numeros)
                        Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            n.toString().padLeft(2, '0'),
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Sorteio: ${TimeUtils.fmtDate(fechamento)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------- auxiliares de UI ----------

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool center;
  const _HeaderCell(this.text, {this.flex = 1, this.center = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TicketRowText extends StatelessWidget {
  final String value;
  final bool selectable;
  const _TicketRowText(this.value, {this.selectable = false, super.key});

  @override
  Widget build(BuildContext context) {
    return selectable ? SelectableText(value) : Text(value);
  }
}

Widget _ticketRow(String label, String value, {bool selectable = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: TextStyle(
                  color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(child: _TicketRowText(value, selectable: selectable)),
      ],
    ),
  );
}
