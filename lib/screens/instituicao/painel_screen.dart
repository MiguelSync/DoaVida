import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/agendamento.dart';
import '../../models/alerta.dart';
import '../../models/instituicao.dart';
import '../../models/tipo_sanguineo.dart';
import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../utils/formatos.dart';
import '../../widgets/comuns.dart';
import 'novo_alerta_screen.dart';

/// Visão geral da instituição: indicadores, estoque e base de doadores.
class PainelScreen extends StatelessWidget {
  const PainelScreen({super.key, required this.irPara});

  /// 1 = alertas, 2 = agenda.
  final ValueChanged<int> irPara;

  void _editarEstoque(BuildContext context, TipoSanguineo tipo, NivelEstoque atual) {
    final estado = context.read<AppState>();
    final mensageiro = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(children: [
                TipoBadge(tipo, tamanho: 44),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Atualizar nível do estoque',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
            for (final n in NivelEstoque.values)
              ListTile(
                leading: CircleAvatar(radius: 8, backgroundColor: AppCores.nivel(n)),
                title: Text(n.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: n == atual
                    ? const Icon(Icons.check, color: AppCores.vermelho)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  estado.definirEstoque(tipo, n);
                  if (n == NivelEstoque.critico && atual != NivelEstoque.critico) {
                    mensageiro
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text('Estoque de ${tipo.label} marcado como crítico.'),
                        duration: const Duration(seconds: 6),
                        action: SnackBarAction(
                          label: 'Criar alerta',
                          onPressed: () => navegador.push(MaterialPageRoute(
                            builder: (_) => NovoAlertaScreen(
                              tipoInicial: TipoAlerta.campanha,
                              tiposIniciais: {tipo},
                            ),
                          )),
                        ),
                      ));
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final inst = estado.instituicaoAtual!;
    final hoje = soData(DateTime.now());
    final ags = estado.agendamentosDaInstituicao(inst.id);
    final deHoje = ags
        .where((a) => soData(a.dataHora) == hoje && a.status.ativo)
        .length;
    final pendentes =
        ags.where((a) => a.status == StatusAgendamento.agendado).length;
    final alertasAtivos =
        estado.alertasDaInstituicao(inst.id).where((a) => a.ativo).length;
    final porTipo = estado.doadoresPorTipo();
    final maior = porTipo.values.fold<int>(0, (m, v) => v > m ? v : m);
    final criticos = inst.tiposNoNivel(NivelEstoque.critico);

    return PaginaLista(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), AppCores.vermelhoEscuro],
            ),
          ),
          child: Row(
            children: [
              Icon(
                inst.tipo == TipoInstituicao.hemocentro
                    ? Icons.water_drop
                    : Icons.local_hospital,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inst.nome,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    Text('${inst.tipo.label} · ${inst.cidade}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85))),
                    Text(inst.horario,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GradeResponsiva(
          larguraMinima: 170,
          children: [
            Indicador(
              icone: Icons.today_outlined,
              valor: '$deHoje',
              rotulo: 'doações agendadas para hoje',
              cor: AppCores.info,
            ),
            Indicador(
              icone: Icons.pending_actions_outlined,
              valor: '$pendentes',
              rotulo: 'aguardando confirmação',
              cor: AppCores.baixo,
            ),
            Indicador(
              icone: Icons.campaign_outlined,
              valor: '$alertasAtivos',
              rotulo: 'alertas ativos',
            ),
            Indicador(
              icone: Icons.groups_outlined,
              valor: '${estado.totalDoadores}',
              rotulo: 'doadores na rede',
              cor: AppCores.estavel,
            ),
          ],
        ),
        if (criticos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Cartao(
            cor: AppCores.critico.withValues(alpha: 0.06),
            corBorda: AppCores.critico.withValues(alpha: 0.3),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppCores.critico),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Estoque crítico de ${TipoSanguineo.juntar(criticos)}. '
                  'Publique um alerta para avisar os doadores compatíveis.',
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => NovoAlertaScreen(
                    tipoInicial: TipoAlerta.campanha,
                    tiposIniciais: criticos.toSet(),
                  ),
                )),
                child: const Text('Alertar'),
              ),
            ]),
          ),
        ],
        const TituloSecao('Estoque de sangue',
            subtitulo: 'Toque em um tipo para atualizar o nível'),
        GradeResponsiva(
          larguraMinima: 140,
          children: [
            for (final t in TipoSanguineo.values)
              Cartao(
                onTap: () => _editarEstoque(context, t, inst.nivel(t)),
                corBorda: AppCores.nivel(inst.nivel(t)).withValues(alpha: 0.4),
                child: Column(
                  children: [
                    TipoBadge(t, tamanho: 48),
                    const SizedBox(height: 10),
                    Etiqueta(inst.nivel(t).label, cor: AppCores.nivel(inst.nivel(t))),
                  ],
                ),
              ),
          ],
        ),
        const TituloSecao('Doadores cadastrados por tipo',
            subtitulo: 'Dados agregados e anônimos (LGPD)'),
        Cartao(
          child: Column(
            children: [
              for (final t in TipoSanguineo.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(t.label,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: maior == 0 ? 0 : porTipo[t]! / maior,
                            minHeight: 12,
                            color: AppCores.vermelho,
                            backgroundColor:
                                AppCores.vermelho.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('${porTipo[t]}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => irPara(2),
                icon: const Icon(Icons.event_note_outlined),
                label: const Text('Ver agenda'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => irPara(1),
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Alertas'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
