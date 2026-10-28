import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alerta.dart';
import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/comuns.dart';
import 'novo_alerta_screen.dart';

/// RF06 — Campanhas e alertas publicados pela instituição.
class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

  Future<void> _encerrar(BuildContext context, Alerta a) async {
    final ok = await confirmar(
      context,
      titulo: 'Encerrar alerta?',
      mensagem: 'O alerta deixará de aparecer para os doadores.',
      botao: 'Encerrar',
    );
    if (!ok || !context.mounted) return;
    context.read<AppState>().encerrarAlerta(a.id);
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final inst = estado.instituicaoAtual!;
    final alertas = estado.alertasDaInstituicao(inst.id);

    return PaginaLista(
      children: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NovoAlertaScreen()),
          ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.campaign),
          label: const Text('Publicar novo alerta'),
        ),
        const SizedBox(height: 6),
        const Text(
          'Os doadores com tipo sanguíneo compatível recebem uma notificação.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppCores.textoSuave),
        ),
        const TituloSecao('Alertas publicados'),
        if (alertas.isEmpty)
          const EstadoVazio(
            icone: Icons.campaign_outlined,
            titulo: 'Nenhum alerta publicado',
            texto: 'Use alertas quando o estoque estiver crítico ou houver '
                'uma urgência médica.',
          )
        else
          for (final a in alertas) ...[
            CartaoAlerta(
              alerta: a,
              rodape: Row(
                children: [
                  const Icon(Icons.people_outline,
                      size: 18, color: AppCores.textoSuave),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${a.notificados} ${a.notificados == 1 ? 'doador notificado' : 'doadores notificados'}',
                      style: const TextStyle(color: AppCores.textoSuave),
                    ),
                  ),
                  if (a.ativo)
                    TextButton(
                      onPressed: () => _encerrar(context, a),
                      child: const Text('Encerrar'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}
