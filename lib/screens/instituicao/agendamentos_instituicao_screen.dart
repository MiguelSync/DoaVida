import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/agendamento.dart';
import '../../models/doador.dart';
import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../utils/formatos.dart';
import '../../widgets/comuns.dart';

enum _Filtro { proximos, hoje, historico }

/// Agenda de doações recebidas pela instituição.
/// Ao registrar a doação, ela entra automaticamente no histórico do doador
/// (alimentando o cálculo de aptidão — RF04).
class AgendamentosInstituicaoScreen extends StatefulWidget {
  const AgendamentosInstituicaoScreen({super.key});

  @override
  State<AgendamentosInstituicaoScreen> createState() =>
      _AgendamentosInstituicaoScreenState();
}

class _AgendamentosInstituicaoScreenState
    extends State<AgendamentosInstituicaoScreen> {
  _Filtro _filtro = _Filtro.proximos;

  Future<void> _registrar(Agendamento a, Doador? d) async {
    final ok = await confirmar(
      context,
      titulo: 'Registrar doação?',
      mensagem: 'Confirma que ${d == null ? 'o doador' : primeiroNome(d.nome)} '
          'realizou a doação? Ela será adicionada ao histórico do doador.',
      botao: 'Registrar',
    );
    if (!ok || !mounted) return;
    context.read<AppState>().alterarStatus(a.id, StatusAgendamento.realizado);
    avisar(context, 'Doação registrada. Obrigado!');
  }

  Future<void> _ligar(String telefone) async {
    try {
      await launchUrl(Uri(scheme: 'tel', path: apenasDigitos(telefone)));
    } catch (_) {
      if (mounted) avisar(context, 'Não foi possível iniciar a ligação.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final inst = estado.instituicaoAtual!;
    final hoje = soData(DateTime.now());
    final todos = estado.agendamentosDaInstituicao(inst.id);

    final List<Agendamento> lista = switch (_filtro) {
      _Filtro.proximos => todos.where((a) => a.status.ativo).toList(),
      _Filtro.hoje =>
        todos.where((a) => soData(a.dataHora) == hoje).toList(),
      _Filtro.historico =>
        todos.where((a) => !a.status.ativo).toList().reversed.toList(),
    };

    return PaginaLista(
      children: [
        SegmentedButton<_Filtro>(
          segments: const [
            ButtonSegment(value: _Filtro.proximos, label: Text('Próximos')),
            ButtonSegment(value: _Filtro.hoje, label: Text('Hoje')),
            ButtonSegment(value: _Filtro.historico, label: Text('Histórico')),
          ],
          selected: {_filtro},
          onSelectionChanged: (s) => setState(() => _filtro = s.first),
        ),
        const SizedBox(height: 8),
        const Text(
          'Por privacidade, só são exibidos o nome reduzido, o tipo sanguíneo '
          'e o telefone do doador.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppCores.textoSuave),
        ),
        const SizedBox(height: 12),
        if (lista.isEmpty)
          const EstadoVazio(
            icone: Icons.event_note_outlined,
            titulo: 'Nenhum agendamento aqui',
          )
        else
          for (final a in lista) ...[
            _ItemAgendamento(
              agendamento: a,
              doador: estado.doadorPorId(a.doadorId),
              onConfirmar: () =>
                  estado.alterarStatus(a.id, StatusAgendamento.confirmado),
              onCancelar: () =>
                  estado.alterarStatus(a.id, StatusAgendamento.cancelado),
              onFaltou: () =>
                  estado.alterarStatus(a.id, StatusAgendamento.faltou),
              onRegistrar: () => _registrar(a, estado.doadorPorId(a.doadorId)),
              onLigar: _ligar,
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ItemAgendamento extends StatelessWidget {
  const _ItemAgendamento({
    required this.agendamento,
    required this.doador,
    required this.onConfirmar,
    required this.onCancelar,
    required this.onFaltou,
    required this.onRegistrar,
    required this.onLigar,
  });

  final Agendamento agendamento;
  final Doador? doador;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;
  final VoidCallback onFaltou;
  final VoidCallback onRegistrar;
  final ValueChanged<String> onLigar;

  @override
  Widget build(BuildContext context) {
    final a = agendamento;
    final d = doador;
    final acoes = <Widget>[
      if (a.status == StatusAgendamento.agendado) ...[
        TextButton(onPressed: onCancelar, child: const Text('Recusar')),
        FilledButton.tonal(onPressed: onConfirmar, child: const Text('Confirmar')),
      ],
      if (a.status == StatusAgendamento.confirmado) ...[
        TextButton(onPressed: onFaltou, child: const Text('Não compareceu')),
        FilledButton(onPressed: onRegistrar, child: const Text('Registrar doação')),
      ],
    ];

    return Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (d != null)
                TipoBadge(d.tipo, tamanho: 46)
              else
                const CircleAvatar(child: Icon(Icons.person_off_outlined)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d == null ? 'Doador removido' : nomeReduzido(d.nome),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      '${fDataExtenso(a.dataHora)} · ${fHora(a.dataHora)}',
                      style: const TextStyle(color: AppCores.textoSuave),
                    ),
                    const SizedBox(height: 6),
                    Etiqueta(a.status.label, cor: AppCores.status(a.status)),
                  ],
                ),
              ),
              if (d != null && d.telefone.isNotEmpty)
                IconButton(
                  tooltip: 'Ligar para ${d.telefone}',
                  onPressed: () => onLigar(d.telefone),
                  icon: const Icon(Icons.phone_outlined),
                ),
            ],
          ),
          if (acoes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 4,
                children: acoes,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
