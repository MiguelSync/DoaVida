import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/doador.dart';
import '../../services/elegibilidade.dart';
import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../utils/formatos.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/comuns.dart';
import '../faq_screen.dart';
import 'novo_agendamento_screen.dart';

class InicioDoadorScreen extends StatelessWidget {
  const InicioDoadorScreen({super.key, required this.irPara});

  /// Troca a aba do shell (1 = mapa, 2 = agenda, 3 = histórico).
  final ValueChanged<int> irPara;

  void _agendar(BuildContext context, {String? instituicaoId}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NovoAgendamentoScreen(instituicaoId: instituicaoId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final d = estado.doadorAtual!;
    final eleg = estado.elegibilidadeDe(d);
    final doacoes = estado.doacoesDe(d.id);
    final agendamento = estado.agendamentoAtivoDe(d.id);
    final alertas = estado.alertasAtivosPara(d);

    return PaginaLista(
      children: [
        _Cabecalho(doador: d, eleg: eleg),
        const SizedBox(height: 14),
        _CartaoAptidao(
          eleg: eleg,
          temAgendamento: agendamento != null,
          onAgendar: () => _agendar(context),
          onVerAgenda: () => irPara(2),
          onFaq: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FaqScreen()),
          ),
        ),
        for (final aviso in eleg.avisos)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Cartao(
              cor: AppCores.info.withValues(alpha: 0.06),
              corBorda: AppCores.info.withValues(alpha: 0.2),
              child: Row(children: [
                const Icon(Icons.info_outline, color: AppCores.info),
                const SizedBox(width: 10),
                Expanded(child: Text(aviso)),
              ]),
            ),
          ),
        if (agendamento != null) ...[
          const TituloSecao('Seu próximo agendamento'),
          CartaoAgendamento(
            agendamento: agendamento,
            instituicao: estado.instituicaoPorId(agendamento.instituicaoId),
            acoes: [
              TextButton(
                onPressed: () => irPara(2),
                child: const Text('Ver detalhes'),
              ),
            ],
          ),
        ],
        TituloSecao(
          'Alertas para o tipo ${d.tipo.label}',
          subtitulo: 'Campanhas ativas que procuram doadores como você',
        ),
        if (alertas.isEmpty)
          const EstadoVazio(
            icone: Icons.notifications_none,
            titulo: 'Nenhum alerta ativo para o seu tipo',
            texto: 'Avisaremos você quando um hemocentro precisar.',
          )
        else
          for (final a in alertas) ...[
            CartaoAlerta(
              alerta: a,
              instituicao: estado.instituicaoPorId(a.instituicaoId),
              rodape: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: agendamento == null && !eleg.impedido
                      ? () => _agendar(context, instituicaoId: a.instituicaoId)
                      : null,
                  icon: const Icon(Icons.event_available),
                  label: const Text('Quero ajudar'),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        const TituloSecao('Atalhos'),
        GradeResponsiva(
          larguraMinima: 150,
          children: [
            _Atalho(
              icone: Icons.map_outlined,
              rotulo: 'Hemocentros próximos',
              onTap: () => irPara(1),
            ),
            _Atalho(
              icone: Icons.event_available_outlined,
              rotulo: 'Agendar doação',
              onTap: () => _agendar(context),
            ),
            _Atalho(
              icone: Icons.history,
              rotulo: 'Meu histórico',
              onTap: () => irPara(3),
            ),
            _Atalho(
              icone: Icons.help_outline,
              rotulo: 'Quem pode doar?',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              ),
            ),
          ],
        ),
        const TituloSecao('Seu impacto'),
        GradeResponsiva(
          larguraMinima: 220,
          maxColunas: 2,
          children: [
            Indicador(
              icone: Icons.water_drop_outlined,
              valor: '${doacoes.length}',
              rotulo: doacoes.length == 1 ? 'doação registrada' : 'doações registradas',
            ),
            Indicador(
              icone: Icons.favorite_border,
              valor: 'até ${doacoes.length * 4}',
              rotulo: 'pessoas que podem ter sido ajudadas',
              cor: AppCores.estavel,
            ),
          ],
        ),
      ],
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.doador, required this.eleg});
  final Doador doador;
  final ResultadoElegibilidade eleg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE53935), AppCores.vermelhoEscuro],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${primeiroNome(doador.nome)}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Obrigado por fazer parte da rede de doadores do Alto Vale.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TipoBadge(doador.tipo, tamanho: 60, claro: true),
        ],
      ),
    );
  }
}

class _CartaoAptidao extends StatelessWidget {
  const _CartaoAptidao({
    required this.eleg,
    required this.temAgendamento,
    required this.onAgendar,
    required this.onVerAgenda,
    required this.onFaq,
  });

  final ResultadoElegibilidade eleg;
  final bool temAgendamento;
  final VoidCallback onAgendar;
  final VoidCallback onVerAgenda;
  final VoidCallback onFaq;

  @override
  Widget build(BuildContext context) {
    final Color cor;
    final IconData icone;
    final String titulo;
    final String texto;

    if (eleg.impedido) {
      cor = AppCores.critico;
      icone = Icons.block;
      titulo = 'No momento você não pode doar';
      texto = eleg.motivos.join('\n');
    } else if (eleg.aptoAgora) {
      cor = AppCores.estavel;
      icone = Icons.check_circle;
      titulo = 'Você está apto(a) para doar!';
      texto = eleg.ultimaDoacao == null
          ? 'Agende sua primeira doação e ajude a salvar vidas.'
          : 'Sua última doação foi em ${fData(eleg.ultimaDoacao!)}.';
    } else {
      final dias = eleg.diasRestantes();
      cor = AppCores.baixo;
      icone = Icons.hourglass_bottom;
      titulo = 'Próxima doação a partir de ${fData(eleg.proximaData!)}';
      texto = 'Faltam $dias ${dias == 1 ? 'dia' : 'dias'}. Você já pode '
          'agendar para essa data ou depois.';
    }

    final Widget acao;
    if (eleg.impedido) {
      acao = OutlinedButton(onPressed: onFaq, child: const Text('Ver requisitos'));
    } else if (temAgendamento) {
      acao = OutlinedButton(
          onPressed: onVerAgenda, child: const Text('Ver meu agendamento'));
    } else {
      acao = FilledButton.icon(
        onPressed: onAgendar,
        icon: const Icon(Icons.event_available),
        label: const Text('Agendar doação'),
      );
    }

    return Cartao(
      corBorda: cor.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: cor, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: cor)),
                    const SizedBox(height: 4),
                    Text(texto),
                  ],
                ),
              ),
            ],
          ),
          if (!eleg.impedido && !eleg.aptoAgora) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: eleg.progresso(),
                minHeight: 10,
                color: cor,
                backgroundColor: cor.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Intervalo de recuperação desde a última doação',
              style: TextStyle(fontSize: 11, color: AppCores.textoSuave.withValues(alpha: 0.9)),
            ),
          ],
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerRight, child: acao),
        ],
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({required this.icone, required this.rotulo, required this.onTap});
  final IconData icone;
  final String rotulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Cartao(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: AppCores.vermelho),
          const SizedBox(height: 10),
          Text(rotulo, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
