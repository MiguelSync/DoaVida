import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alerta.dart';
import '../../models/tipo_sanguineo.dart';
import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../widgets/comuns.dart';

/// RF06 + RF07 — Publicação de alerta com cálculo automático de doadores
/// compatíveis.
///
/// - Urgência: informa o tipo do PACIENTE; o app calcula os tipos de doador
///   compatíveis pela tabela ABO/Rh.
/// - Estoque crítico: escolhe diretamente os tipos em falta.
class NovoAlertaScreen extends StatefulWidget {
  const NovoAlertaScreen({super.key, this.tipoInicial, this.tiposIniciais});

  final TipoAlerta? tipoInicial;
  final Set<TipoSanguineo>? tiposIniciais;

  @override
  State<NovoAlertaScreen> createState() => _NovoAlertaScreenState();
}

class _NovoAlertaScreenState extends State<NovoAlertaScreen> {
  late TipoAlerta _tipo;
  TipoSanguineo? _receptor;
  late Set<TipoSanguineo> _tiposEstoque;
  final _titulo = TextEditingController();
  final _mensagem = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial ?? TipoAlerta.campanha;
    _tiposEstoque = {...?widget.tiposIniciais};
  }

  @override
  void dispose() {
    _titulo.dispose();
    _mensagem.dispose();
    super.dispose();
  }

  Set<TipoSanguineo> get _tiposAlvo => _tipo == TipoAlerta.urgencia
      ? (_receptor?.podeReceberDe ?? <TipoSanguineo>{})
      : _tiposEstoque;

  String get _tituloSugerido {
    if (_tipo == TipoAlerta.urgencia) {
      return _receptor == null
          ? 'Urgência: paciente precisa de doação'
          : 'Urgência: paciente ${_receptor!.label} precisa de doação';
    }
    return _tiposEstoque.isEmpty
        ? 'Estoque crítico'
        : 'Estoque crítico de ${TipoSanguineo.juntar(_tiposEstoque)}';
  }

  String get _mensagemSugerida => _tipo == TipoAlerta.urgencia
      ? 'Temos um paciente em situação de urgência. Se você é compatível, '
          'agende sua doação o quanto antes.'
      : 'Nossos estoques estão baixos. Agende sua doação pelo app e ajude a '
          'salvar vidas!';

  Future<void> _publicar() async {
    if (_tiposAlvo.isEmpty) {
      avisar(context, 'Selecione o tipo sanguíneo.');
      return;
    }
    setState(() => _enviando = true);
    final titulo =
        _titulo.text.trim().isEmpty ? _tituloSugerido : _titulo.text.trim();
    final mensagem = _mensagem.text.trim().isEmpty
        ? _mensagemSugerida
        : _mensagem.text.trim();
    final mensageiro = ScaffoldMessenger.of(context);
    final n = await context.read<AppState>().publicarAlerta(
          tipo: _tipo,
          titulo: titulo,
          mensagem: mensagem,
          tipos: _tiposAlvo,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    mensageiro.showSnackBar(SnackBar(
      content: Text(n == 0
          ? 'Alerta publicado. Nenhum doador compatível com notificações ativas no momento.'
          : 'Alerta publicado! $n ${n == 1 ? 'doador compatível foi notificado' : 'doadores compatíveis foram notificados'}.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final alvo = estado.doadoresParaTipos(_tiposAlvo);

    return Scaffold(
      appBar: AppBar(title: const Text('Novo alerta')),
      body: PaginaLista(
        maxLargura: 720,
        children: [
          const TituloSecao('Tipo de alerta'),
          SegmentedButton<TipoAlerta>(
            segments: const [
              ButtonSegment(
                value: TipoAlerta.campanha,
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('Estoque crítico'),
              ),
              ButtonSegment(
                value: TipoAlerta.urgencia,
                icon: Icon(Icons.priority_high),
                label: Text('Urgência'),
              ),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
          if (_tipo == TipoAlerta.urgencia) ...[
            const TituloSecao('Tipo sanguíneo do paciente',
                subtitulo: 'O app calcula quais doadores são compatíveis'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in TipoSanguineo.values)
                  ChoiceChip(
                    label: SizedBox(
                      width: 36,
                      child: Text(t.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    selected: _receptor == t,
                    onSelected: (_) => setState(() => _receptor = t),
                  ),
              ],
            ),
            if (_receptor != null) ...[
              const SizedBox(height: 12),
              Cartao(
                cor: AppCores.info.withValues(alpha: 0.05),
                corBorda: AppCores.info.withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paciente ${_receptor!.label} pode receber de:',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TiposLinha(_receptor!.podeReceberDe, tamanho: 34),
                  ],
                ),
              ),
            ],
          ] else ...[
            const TituloSecao('Tipos em falta',
                subtitulo: 'Selecione um ou mais tipos'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in TipoSanguineo.values)
                  FilterChip(
                    label: Text(t.label,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    selected: _tiposEstoque.contains(t),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _tiposEstoque.add(t);
                      } else {
                        _tiposEstoque.remove(t);
                      }
                    }),
                  ),
              ],
            ),
          ],
          const TituloSecao('Mensagem'),
          TextField(
            controller: _titulo,
            decoration: campo('Título (opcional)',
                icone: Icons.title, dica: _tituloSugerido),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mensagem,
            minLines: 3,
            maxLines: 5,
            decoration: campo('Mensagem (opcional)', dica: _mensagemSugerida),
          ),
          const SizedBox(height: 20),
          Cartao(
            cor: AppCores.vermelho.withValues(alpha: 0.05),
            corBorda: AppCores.vermelho.withValues(alpha: 0.25),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined,
                    color: AppCores.vermelho),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _tiposAlvo.isEmpty
                        ? 'Selecione o tipo sanguíneo para ver quantos doadores serão avisados.'
                        : '${alvo.length} ${alvo.length == 1 ? 'doador compatível será notificado' : 'doadores compatíveis serão notificados'} '
                            '(tipos ${TipoSanguineo.juntar(_tiposAlvo)}, com alertas ativos).',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _enviando || _tiposAlvo.isEmpty ? null : _publicar,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.send),
            label: const Text('Publicar e notificar'),
          ),
        ],
      ),
    );
  }
}
