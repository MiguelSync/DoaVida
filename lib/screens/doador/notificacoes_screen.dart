import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../utils/formatos.dart';
import '../../widgets/comuns.dart';

/// Central de notificações do doador (RF07).
class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final d = estado.doadorAtual;
    if (d == null) return const Scaffold();
    final lista = estado.notificacoesDe(d.id);
    final naoLidas = estado.naoLidasDe(d.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (naoLidas > 0)
            TextButton(
              onPressed: () => estado.marcarTodasLidas(d.id),
              child: const Text('Marcar todas como lidas'),
            ),
        ],
      ),
      body: PaginaLista(
        maxLargura: 720,
        children: [
          if (!d.notificacoes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Cartao(
                cor: AppCores.baixo.withValues(alpha: 0.06),
                child: Row(children: [
                  const Icon(Icons.notifications_off_outlined,
                      color: AppCores.baixo),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Os alertas estão desativados. Você não '
                        'receberá novos avisos.'),
                  ),
                  TextButton(
                    onPressed: () => estado.definirNotificacoes(true),
                    child: const Text('Ativar'),
                  ),
                ]),
              ),
            ),
          if (lista.isEmpty)
            const EstadoVazio(
              icone: Icons.notifications_none,
              titulo: 'Nenhuma notificação',
              texto: 'Quando um hemocentro precisar do seu tipo sanguíneo, '
                  'o aviso aparece aqui.',
            )
          else
            for (final n in lista) ...[
              Cartao(
                onTap: () => estado.marcarLida(n.id),
                cor: n.lida ? null : AppCores.vermelho.withValues(alpha: 0.04),
                corBorda:
                    n.lida ? null : AppCores.vermelho.withValues(alpha: 0.25),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      n.lida ? Icons.campaign_outlined : Icons.campaign,
                      color: AppCores.vermelho,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.titulo,
                              style: TextStyle(
                                  fontWeight: n.lida
                                      ? FontWeight.w600
                                      : FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(n.corpo),
                          const SizedBox(height: 6),
                          Text(fRelativo(n.criadaEm),
                              style: const TextStyle(
                                  fontSize: 12, color: AppCores.textoSuave)),
                        ],
                      ),
                    ),
                    if (!n.lida)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: const BoxDecoration(
                            color: AppCores.vermelho, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
