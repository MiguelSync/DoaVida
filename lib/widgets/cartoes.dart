import 'package:flutter/material.dart';

import '../models/agendamento.dart';
import '../models/alerta.dart';
import '../models/instituicao.dart';
import '../theme/tema.dart';
import '../utils/formatos.dart';
import 'comuns.dart';

/// Cartão de alerta/campanha (usado pelo doador e pela instituição).
class CartaoAlerta extends StatelessWidget {
  const CartaoAlerta({
    super.key,
    required this.alerta,
    this.instituicao,
    this.rodape,
  });

  final Alerta alerta;
  final Instituicao? instituicao;
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    final urgente = alerta.tipo == TipoAlerta.urgencia;
    final cor = !alerta.ativo
        ? AppCores.textoSuave
        : (urgente ? AppCores.critico : AppCores.baixo);
    return Cartao(
      corBorda: alerta.ativo ? cor.withValues(alpha: 0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Etiqueta(
                alerta.ativo ? alerta.tipo.label : 'Encerrado',
                cor: cor,
                icone: urgente ? Icons.priority_high : Icons.campaign_outlined,
              ),
              const Spacer(),
              Text(fRelativo(alerta.criadoEm),
                  style: const TextStyle(
                      fontSize: 12, color: AppCores.textoSuave)),
            ],
          ),
          const SizedBox(height: 10),
          Text(alerta.titulo,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          if (instituicao != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('${instituicao!.nome} · ${instituicao!.cidade}',
                  style: const TextStyle(color: AppCores.textoSuave)),
            ),
          const SizedBox(height: 8),
          Text(alerta.mensagem),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Doadores procurados: ',
                  style: TextStyle(fontSize: 12, color: AppCores.textoSuave)),
              Expanded(child: TiposLinha(alerta.tiposNecessarios, tamanho: 28)),
            ],
          ),
          if (rodape != null) ...[const SizedBox(height: 12), rodape!],
        ],
      ),
    );
  }
}

/// Cartão de agendamento do ponto de vista do doador.
class CartaoAgendamento extends StatelessWidget {
  const CartaoAgendamento({
    super.key,
    required this.agendamento,
    this.instituicao,
    this.acoes = const [],
  });

  final Agendamento agendamento;
  final Instituicao? instituicao;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context) {
    final a = agendamento;
    return Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BlocoData(a.dataHora),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(instituicao?.nome ?? 'Instituição',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${fDataExtenso(a.dataHora)} · ${fHora(a.dataHora)}',
                      style: const TextStyle(color: AppCores.textoSuave),
                    ),
                    if (instituicao != null)
                      Text(instituicao!.cidade,
                          style: const TextStyle(color: AppCores.textoSuave)),
                    const SizedBox(height: 8),
                    Etiqueta(a.status.label, cor: AppCores.status(a.status)),
                  ],
                ),
              ),
            ],
          ),
          if (acoes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: acoes),
          ],
        ],
      ),
    );
  }
}

class _BlocoData extends StatelessWidget {
  const _BlocoData(this.data);
  final DateTime data;

  static const _meses = [
    'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
    'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppCores.vermelho.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text('${data.day}',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppCores.vermelho)),
          Text(_meses[data.month - 1],
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppCores.vermelho)),
        ],
      ),
    );
  }
}
