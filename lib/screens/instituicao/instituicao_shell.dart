import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/agendamento.dart';
import '../../state/app_state.dart';
import '../../widgets/comuns.dart';
import '../../widgets/shell_adaptativo.dart';
import '../faq_screen.dart';
import 'agendamentos_instituicao_screen.dart';
import 'alertas_screen.dart';
import 'painel_screen.dart';

/// RF02 — Painel de acesso para hospitais e hemocentros.
class InstituicaoShell extends StatefulWidget {
  const InstituicaoShell({super.key});

  @override
  State<InstituicaoShell> createState() => _InstituicaoShellState();
}

class _InstituicaoShellState extends State<InstituicaoShell> {
  int _aba = 0;

  Future<void> _menu(String opcao) async {
    final estado = context.read<AppState>();
    switch (opcao) {
      case 'faq':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FaqScreen()),
        );
      case 'demo':
        final ok = await confirmar(
          context,
          titulo: 'Restaurar demonstração?',
          mensagem: 'Todos os dados (doadores, agendamentos, alertas e '
              'estoques) voltarão ao estado inicial e você sairá da conta.',
          botao: 'Restaurar',
          perigoso: true,
        );
        if (ok) await estado.restaurarDemonstracao();
      case 'sair':
        await estado.sair();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final inst = estado.instituicaoAtual;
    if (inst == null) return const Scaffold();

    final pendentes = estado
        .agendamentosDaInstituicao(inst.id)
        .where((a) => a.status == StatusAgendamento.agendado)
        .length;

    final Widget corpo = switch (_aba) {
      0 => PainelScreen(irPara: (i) => setState(() => _aba = i)),
      1 => const AlertasScreen(),
      _ => const AgendamentosInstituicaoScreen(),
    };

    return ShellAdaptativo(
      titulo: inst.nome,
      indice: _aba,
      aoMudar: (i) => setState(() => _aba = i),
      corpo: corpo,
      acoes: [
        PopupMenuButton<String>(
          tooltip: 'Opções',
          onSelected: _menu,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'faq',
              child: ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('FAQ de doação'),
              ),
            ),
            PopupMenuItem(
              value: 'demo',
              child: ListTile(
                leading: Icon(Icons.restart_alt),
                title: Text('Restaurar demonstração'),
              ),
            ),
            PopupMenuItem(
              value: 'sair',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Sair'),
              ),
            ),
          ],
        ),
      ],
      destinos: [
        const DestinoNav(Icons.dashboard_outlined, Icons.dashboard, 'Painel'),
        const DestinoNav(Icons.campaign_outlined, Icons.campaign, 'Alertas'),
        DestinoNav(Icons.event_note_outlined, Icons.event_note, 'Agenda',
            badge: pendentes),
      ],
    );
  }
}
