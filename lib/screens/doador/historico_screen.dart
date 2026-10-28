import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/doacao.dart';
import '../../services/elegibilidade.dart';
import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../utils/formatos.dart';
import '../../widgets/comuns.dart';

/// RF04 — Histórico de doações e cálculo automático da próxima data.
class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  void _informar(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _InformarDoacaoSheet(),
    );
  }

  Future<void> _remover(BuildContext context, Doacao d) async {
    final ok = await confirmar(
      context,
      titulo: 'Remover doação?',
      mensagem: 'A doação de ${fData(d.data)} será removida do seu histórico.',
      botao: 'Remover',
      perigoso: true,
    );
    if (!ok || !context.mounted) return;
    context.read<AppState>().removerDoacaoInformada(d.id);
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final doador = estado.doadorAtual!;
    final doacoes = estado.doacoesDe(doador.id);
    final eleg = estado.elegibilidadeDe(doador);

    final String proxima;
    if (eleg.impedido) {
      proxima = 'Indisponível';
    } else if (eleg.aptoAgora) {
      proxima = 'Hoje';
    } else {
      proxima = fData(eleg.proximaData!);
    }

    return PaginaLista(
      children: [
        GradeResponsiva(
          larguraMinima: 180,
          maxColunas: 3,
          children: [
            Indicador(
              icone: Icons.water_drop_outlined,
              valor: '${doacoes.length}',
              rotulo: 'doações no total',
            ),
            Indicador(
              icone: Icons.event_outlined,
              valor: doacoes.isEmpty ? '—' : fData(doacoes.first.data),
              rotulo: 'última doação',
              cor: AppCores.info,
            ),
            Indicador(
              icone: Icons.event_available_outlined,
              valor: proxima,
              rotulo: 'apto(a) para doar a partir de',
              cor: eleg.aptoAgora ? AppCores.estavel : AppCores.baixo,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Cartao(
          cor: AppCores.info.withValues(alpha: 0.05),
          corBorda: AppCores.info.withValues(alpha: 0.2),
          child: Text(
            'Regra aplicada para ${doador.sexo.label.toLowerCase()}: intervalo '
            'mínimo de ${Elegibilidade.intervaloDias(doador.sexo)} dias e no '
            'máximo ${Elegibilidade.maximoPorAno(doador.sexo)} doações em 12 meses.',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        TituloSecao(
          'Minhas doações',
          acao: TextButton.icon(
            onPressed: () => _informar(context),
            icon: const Icon(Icons.add),
            label: const Text('Informar doação'),
          ),
        ),
        if (doacoes.isEmpty)
          EstadoVazio(
            icone: Icons.water_drop_outlined,
            titulo: 'Nenhuma doação registrada ainda',
            texto: 'Já doou antes de usar o app? Informe a data para que o '
                'cálculo da próxima doação fique correto.',
            acao: OutlinedButton(
              onPressed: () => _informar(context),
              child: const Text('Informar doação anterior'),
            ),
          )
        else
          Cartao(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < doacoes.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 72),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppCores.vermelho.withValues(alpha: 0.1),
                      child: Text('${doacoes.length - i}º',
                          style: const TextStyle(
                              color: AppCores.vermelho,
                              fontWeight: FontWeight.w800)),
                    ),
                    title: Text(fData(doacoes[i].data),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${doacoes[i].local}\n'
                      '${doacoes[i].informadaPeloDoador ? 'Informada por você' : 'Registrada pela instituição'}',
                    ),
                    isThreeLine: true,
                    trailing: doacoes[i].informadaPeloDoador
                        ? IconButton(
                            tooltip: 'Remover',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _remover(context, doacoes[i]),
                          )
                        : const Icon(Icons.verified_outlined,
                            color: AppCores.estavel),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _InformarDoacaoSheet extends StatefulWidget {
  const _InformarDoacaoSheet();

  @override
  State<_InformarDoacaoSheet> createState() => _InformarDoacaoSheetState();
}

class _InformarDoacaoSheetState extends State<_InformarDoacaoSheet> {
  DateTime? _data;
  final _local = TextEditingController();

  @override
  void dispose() {
    _local.dispose();
    super.dispose();
  }

  Future<void> _escolher() async {
    final hoje = DateTime.now();
    final r = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje,
      firstDate: DateTime(hoje.year - 30),
      lastDate: hoje,
      helpText: 'Data da doação',
    );
    if (r != null) setState(() => _data = r);
  }

  void _salvar() {
    if (_data == null) return;
    context.read<AppState>().informarDoacao(_data!, _local.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Informar doação anterior',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Use para doações feitas antes de usar o app ou fora das '
            'instituições cadastradas.',
            style: TextStyle(color: AppCores.textoSuave),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _escolher,
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                alignment: Alignment.centerLeft),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(_data == null ? 'Data da doação' : fData(_data!)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _local,
            textCapitalization: TextCapitalization.words,
            decoration: campo('Local (opcional)',
                icone: Icons.place_outlined, dica: 'Ex.: Hemosc Joinville'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _data == null ? null : _salvar,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Salvar no histórico'),
          ),
        ],
      ),
    );
  }
}
