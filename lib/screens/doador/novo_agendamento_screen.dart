import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/instituicao.dart';
import '../../services/elegibilidade.dart';
import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../utils/formatos.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/comuns.dart';
import '../faq_screen.dart';

/// RF03 — Agendamento de doação.
/// Respeita a data de aptidão (RF04), dias de funcionamento e a lotação
/// de cada horário.
class NovoAgendamentoScreen extends StatefulWidget {
  const NovoAgendamentoScreen({super.key, this.instituicaoId});
  final String? instituicaoId;

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  String? _instituicaoId;
  DateTime? _dia;
  String? _hora;
  bool _concluido = false;

  @override
  void initState() {
    super.initState();
    _instituicaoId = widget.instituicaoId;
  }

  /// Sábado: 8h–12h. Seg. a sex.: 8h–16h30. Intervalos de 30 min.
  List<String> _horarios(DateTime dia) {
    final fim = dia.weekday == DateTime.saturday ? 12 * 60 : 16 * 60 + 30;
    final lista = <String>[];
    for (var m = 8 * 60; m < fim; m += 30) {
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final mm = (m % 60).toString().padLeft(2, '0');
      lista.add('$h:$mm');
    }
    return lista;
  }

  DateTime _combinar(DateTime dia, String hora) {
    final p = hora.split(':');
    return DateTime(dia.year, dia.month, dia.day, int.parse(p[0]), int.parse(p[1]));
  }

  DateTime _primeiraData(ResultadoElegibilidade e) {
    var d = somarDias(soData(DateTime.now()), 1);
    if (e.proximaData != null && e.proximaData!.isAfter(d)) d = e.proximaData!;
    while (d.weekday == DateTime.sunday) {
      d = somarDias(d, 1);
    }
    return d;
  }

  Future<void> _escolherDia(DateTime primeira) async {
    final ultima = somarDias(primeira, 60);
    var inicial = _dia ?? primeira;
    if (inicial.isBefore(primeira) || inicial.isAfter(ultima)) inicial = primeira;
    final r = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primeira,
      lastDate: ultima,
      selectableDayPredicate: (d) => d.weekday != DateTime.sunday,
      helpText: 'Dia da doação',
    );
    if (r == null) return;
    setState(() {
      _dia = soData(r);
      _hora = null;
    });
  }

  Future<void> _confirmar() async {
    final estado = context.read<AppState>();
    final erro = estado.agendar(_instituicaoId!, _combinar(_dia!, _hora!));
    if (erro != null) {
      avisar(context, erro);
      return;
    }
    // Mantém o formulário visível atrás do diálogo de sucesso.
    _concluido = true;
    final inst = estado.instituicaoPorId(_instituicaoId!);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppCores.estavel, size: 48),
        title: const Text('Doação agendada!'),
        content: Text(
          '${inst?.nome ?? ''}\n${fDataExtenso(_dia!)} às $_hora\n\n'
          'A instituição vai confirmar seu horário. Lembre-se de levar um '
          'documento com foto e de estar alimentado(a).',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final d = estado.doadorAtual;
    if (d == null) return const Scaffold();
    final eleg = estado.elegibilidadeDe(d);
    final ativo = estado.agendamentoAtivoDe(d.id);

    Widget corpo;
    var podeConfirmar = false;

    if (eleg.impedido) {
      corpo = PaginaLista(maxLargura: 720, children: [
        EstadoVazio(
          icone: Icons.block,
          titulo: 'No momento você não pode agendar',
          texto: eleg.motivos.join('\n'),
          acao: OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FaqScreen()),
            ),
            child: const Text('Ver requisitos para doar'),
          ),
        ),
      ]);
    } else if (ativo != null && !_concluido) {
      corpo = PaginaLista(maxLargura: 720, children: [
        const EstadoVazio(
          icone: Icons.event_busy,
          titulo: 'Você já tem um agendamento ativo',
          texto: 'Para marcar um novo horário, cancele o atual na aba Agenda.',
        ),
        const SizedBox(height: 12),
        CartaoAgendamento(
          agendamento: ativo,
          instituicao: estado.instituicaoPorId(ativo.instituicaoId),
        ),
      ]);
    } else {
      final primeira = _primeiraData(eleg);
      final instituicoes = [...estado.instituicoes]
        ..sort((a, b) => a.nome.compareTo(b.nome));
      podeConfirmar = _instituicaoId != null && _dia != null && _hora != null;

      corpo = PaginaLista(maxLargura: 720, children: [
        if (!eleg.aptoAgora)
          Cartao(
            cor: AppCores.baixo.withValues(alpha: 0.06),
            corBorda: AppCores.baixo.withValues(alpha: 0.25),
            child: Row(children: [
              const Icon(Icons.hourglass_bottom, color: AppCores.baixo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pelo intervalo entre doações, você pode agendar a partir de '
                  '${fData(eleg.proximaData!)}.',
                ),
              ),
            ]),
          ),
        const TituloSecao('1. Onde você quer doar?'),
        for (final i in instituicoes) ...[
          _OpcaoInstituicao(
            instituicao: i,
            selecionada: _instituicaoId == i.id,
            onTap: () => setState(() {
              _instituicaoId = i.id;
              _hora = null;
            }),
          ),
          const SizedBox(height: 8),
        ],
        const TituloSecao('2. Qual dia?',
            subtitulo: 'Atendimento de segunda a sábado'),
        OutlinedButton.icon(
          onPressed: () => _escolherDia(primeira),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(_dia == null ? 'Escolher data' : fDataExtenso(_dia!)),
        ),
        if (_dia != null) ...[
          TituloSecao('3. Qual horário?',
              subtitulo: _instituicaoId == null
                  ? 'Escolha primeiro o local'
                  : 'Horários cinza estão lotados'),
          if (_instituicaoId != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in _horarios(_dia!))
                  Builder(builder: (context) {
                    final lotado = estado.ocupacao(
                            _instituicaoId!, _combinar(_dia!, h)) >=
                        AppState.capacidadePorHorario;
                    return ChoiceChip(
                      label: Text(h),
                      selected: _hora == h,
                      onSelected:
                          lotado ? null : (_) => setState(() => _hora = h),
                    );
                  }),
              ],
            ),
        ],
        const TituloSecao('Antes de ir'),
        const Cartao(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Dica(Icons.badge_outlined, 'Leve um documento oficial com foto.'),
              _Dica(Icons.restaurant_outlined,
                  'Esteja alimentado(a) — não precisa de jejum. Evite gordura nas 3 h anteriores.'),
              _Dica(Icons.bedtime_outlined,
                  'Durma pelo menos 6 horas na noite anterior.'),
              _Dica(Icons.no_drinks_outlined,
                  'Não consuma bebida alcoólica nas 12 horas anteriores.'),
              _Dica(Icons.local_drink_outlined, 'Beba bastante água.'),
            ],
          ),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agendar doação')),
      body: SafeArea(child: corpo),
      bottomNavigationBar: (eleg.impedido || (ativo != null && !_concluido))
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: FilledButton(
                      onPressed: podeConfirmar ? _confirmar : null,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52)),
                      child: Text(podeConfirmar
                          ? 'Confirmar ${fDataCurta(_dia!)} às $_hora'
                          : 'Escolha local, dia e horário'),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _OpcaoInstituicao extends StatelessWidget {
  const _OpcaoInstituicao({
    required this.instituicao,
    required this.selecionada,
    required this.onTap,
  });

  final Instituicao instituicao;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final i = instituicao;
    final criticos = i.tiposNoNivel(NivelEstoque.critico);
    return Cartao(
      onTap: onTap,
      cor: selecionada ? AppCores.vermelho.withValues(alpha: 0.05) : null,
      corBorda: selecionada ? AppCores.vermelho : null,
      child: Row(
        children: [
          Icon(
            selecionada ? Icons.check_circle : Icons.circle_outlined,
            color: selecionada ? AppCores.vermelho : AppCores.textoSuave,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.nome,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${i.cidade} · ${i.horario}',
                    style: const TextStyle(
                        fontSize: 12, color: AppCores.textoSuave)),
                if (criticos.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Etiqueta(
                    'Precisa urgente de ${criticos.map((t) => t.label).join(', ')}',
                    cor: AppCores.critico,
                    icone: Icons.priority_high,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dica extends StatelessWidget {
  const _Dica(this.icone, this.texto);
  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: AppCores.vermelho),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
