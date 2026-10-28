import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/shell_adaptativo.dart';
import 'agendamentos_doador_screen.dart';
import 'historico_screen.dart';
import 'inicio_doador_screen.dart';
import 'mapa_screen.dart';
import 'notificacoes_screen.dart';
import 'perfil_screen.dart';

/// Área do doador com navegação por abas.
class DoadorShell extends StatefulWidget {
  const DoadorShell({super.key});

  @override
  State<DoadorShell> createState() => _DoadorShellState();
}

class _DoadorShellState extends State<DoadorShell> {
  int _aba = 0;

  static const _titulos = [
    'DoaVida',
    'Onde doar',
    'Meus agendamentos',
    'Histórico de doações',
    'Meu perfil',
  ];

  void _ir(int aba) => setState(() => _aba = aba);

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final doador = estado.doadorAtual;
    if (doador == null) return const Scaffold();

    final naoLidas = estado.naoLidasDe(doador.id);
    final temAgendamento = estado.agendamentoAtivoDe(doador.id) != null;

    final Widget corpo = switch (_aba) {
      0 => InicioDoadorScreen(irPara: _ir),
      1 => const MapaScreen(),
      2 => const AgendamentosDoadorScreen(),
      3 => const HistoricoScreen(),
      _ => const PerfilScreen(),
    };

    return ShellAdaptativo(
      titulo: _titulos[_aba],
      indice: _aba,
      aoMudar: _ir,
      corpo: corpo,
      acoes: [
        IconButton(
          tooltip: 'Notificações',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
          ),
          icon: Badge(
            isLabelVisible: naoLidas > 0,
            label: Text('$naoLidas'),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
      ],
      destinos: [
        const DestinoNav(Icons.home_outlined, Icons.home, 'Início'),
        const DestinoNav(Icons.map_outlined, Icons.map, 'Mapa'),
        DestinoNav(Icons.event_outlined, Icons.event, 'Agenda',
            badge: temAgendamento ? 1 : 0),
        const DestinoNav(Icons.history, Icons.history, 'Histórico'),
        const DestinoNav(Icons.person_outline, Icons.person, 'Perfil'),
      ],
    );
  }
}
