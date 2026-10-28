import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/agendamento.dart';
import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/comuns.dart';
import 'novo_agendamento_screen.dart';

class AgendamentosDoadorScreen extends StatelessWidget {
  const AgendamentosDoadorScreen({super.key});

  Future<void> _cancelar(BuildContext context, Agendamento a) async {
    final ok = await confirmar(
      context,
      titulo: 'Cancelar agendamento?',
      mensagem: 'O horário será liberado para outro doador.',
      botao: 'Cancelar agendamento',
      perigoso: true,
    );
    if (!ok || !context.mounted) return;
    context.read<AppState>().cancelarAgendamento(a.id);
    avisar(context, 'Agendamento cancelado.');
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final d = estado.doadorAtual!;
    final todos = estado.agendamentosDoDoador(d.id);
    final ativos = todos.where((a) => a.status.ativo).toList().reversed.toList();
    final anteriores = todos.where((a) => !a.status.ativo).toList();

    return PaginaLista(
      children: [
        FilledButton.icon(
          onPressed: ativos.isEmpty
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const NovoAgendamentoScreen(),
                  ))
              : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.add),
          label: const Text('Novo agendamento'),
        ),
        if (ativos.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Você pode ter um agendamento ativo por vez.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppCores.textoSuave),
            ),
          ),
        const TituloSecao('Ativos'),
        if (ativos.isEmpty)
          const EstadoVazio(
            icone: Icons.event_available_outlined,
            titulo: 'Nenhum agendamento ativo',
            texto: 'Escolha um hemocentro, o dia e o horário que preferir.',
          )
        else
          for (final a in ativos) ...[
            CartaoAgendamento(
              agendamento: a,
              instituicao: estado.instituicaoPorId(a.instituicaoId),
              acoes: [
                TextButton.icon(
                  onPressed: () => _cancelar(context, a),
                  style: TextButton.styleFrom(foregroundColor: AppCores.critico),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        if (anteriores.isNotEmpty) ...[
          const TituloSecao('Anteriores'),
          for (final a in anteriores) ...[
            CartaoAgendamento(
              agendamento: a,
              instituicao: estado.instituicaoPorId(a.instituicaoId),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}
