import 'package:flutter/material.dart';

import '../theme/tema.dart';
import '../widgets/comuns.dart';

class _Topico {
  const _Topico(this.titulo, this.icone, this.cor, this.itens);
  final String titulo;
  final IconData icone;
  final Color cor;
  final List<(String, String)> itens;
}

/// RF08 — Seção informativa: requisitos, preparativos e impedimentos.
/// Conteúdo resumido das orientações do Ministério da Saúde.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _topicos = <_Topico>[
    _Topico('Requisitos básicos', Icons.check_circle_outline, AppCores.estavel, [
      (
        'Quem pode doar sangue?',
        'Pessoas entre 16 e 69 anos, 11 meses e 29 dias, com peso mínimo de '
            '50 kg e em boas condições de saúde. Menores de 18 anos precisam do '
            'consentimento formal do responsável legal. Pessoas entre 60 e 69 '
            'anos só podem doar se já tiverem doado antes dos 60.'
      ),
      (
        'Preciso levar algum documento?',
        'Sim. Um documento oficial de identificação com foto (RG, CNH, carteira '
            'de trabalho, passaporte etc.). Documentos digitais com foto também '
            'são aceitos.'
      ),
      (
        'Com que frequência posso doar?',
        'Homens: a cada 60 dias, no máximo 4 vezes em 12 meses.\n'
            'Mulheres: a cada 90 dias, no máximo 3 vezes em 12 meses.\n'
            'O DoaVida calcula automaticamente a sua próxima data.'
      ),
      (
        'Quanto tempo leva e quanto sangue é coletado?',
        'São coletados cerca de 450 mL. A coleta em si leva poucos minutos; com '
            'cadastro, triagem e lanche, o processo todo costuma levar em torno '
            'de uma hora.'
      ),
      (
        'Doar sangue é seguro?',
        'Sim. Todo o material utilizado é estéril e descartável — não há risco '
            'de contrair doenças ao doar.'
      ),
    ]),
    _Topico('Antes e depois de doar', Icons.restaurant_outlined, AppCores.info, [
      (
        'Preciso estar em jejum?',
        'Não! Nunca doe em jejum. Esteja alimentado(a), evitando alimentos '
            'gordurosos nas 3 horas anteriores. Se a doação for depois do '
            'almoço, aguarde 2 horas.'
      ),
      (
        'Preciso dormir bem?',
        'Sim. É necessário ter dormido pelo menos 6 horas nas últimas 24 horas.'
      ),
      (
        'Posso beber álcool ou fumar?',
        'Não ingira bebida alcoólica nas 12 horas anteriores à doação. Evite '
            'fumar por pelo menos 2 horas antes e depois.'
      ),
      (
        'Cuidados após a doação',
        'Faça o lanche oferecido, beba bastante líquido, evite esforço físico '
            'intenso no restante do dia e mantenha o curativo por algumas horas.'
      ),
    ]),
    _Topico('Impedimentos temporários', Icons.schedule, AppCores.baixo, [
      (
        'Gripe, resfriado ou febre',
        'Aguarde 7 dias após o desaparecimento dos sintomas.'
      ),
      (
        'Gravidez, parto e amamentação',
        'Gestantes não podem doar. Após o parto, aguarde 90 dias (parto normal) '
            'ou 180 dias (cesariana). Durante a amamentação, se o parto ocorreu '
            'há menos de 12 meses, a doação também não é indicada.'
      ),
      (
        'Tatuagem, piercing ou maquiagem definitiva',
        'Em geral, é preciso aguardar 12 meses após o procedimento. Informe na '
            'triagem.'
      ),
      (
        'Procedimentos odontológicos',
        'Extração, tratamento de canal ou cirurgia odontológica exigem um '
            'intervalo que varia conforme o procedimento (de alguns dias a uma '
            'semana).'
      ),
      (
        'Exames endoscópicos',
        'Após endoscopia ou colonoscopia, aguarde 6 meses.'
      ),
      (
        'Vacinas e medicamentos',
        'O intervalo depende da vacina ou do medicamento. Informe tudo o que '
            'você tomou recentemente na triagem.'
      ),
      (
        'Situações de risco para ISTs',
        'Situações com maior risco de infecções sexualmente transmissíveis '
            'exigem aguardar 12 meses.'
      ),
      (
        'Viagens',
        'Viagens recentes para regiões com malária ou outras doenças endêmicas '
            'podem impedir a doação temporariamente.'
      ),
    ]),
    _Topico('Impedimentos definitivos', Icons.block, AppCores.critico, [
      (
        'Quem não pode doar nunca?',
        '• Quem teve hepatite após os 11 anos de idade;\n'
            '• Quem tem evidência clínica ou laboratorial de hepatites B ou C, '
            'HIV, HTLV I e II ou doença de Chagas;\n'
            '• Quem fez uso de drogas ilícitas injetáveis;\n'
            '• Quem teve malária.'
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quem pode doar?')),
      body: PaginaLista(
        maxLargura: 760,
        children: [
          Cartao(
            cor: AppCores.vermelho.withValues(alpha: 0.05),
            child: const Row(
              children: [
                Icon(Icons.favorite, color: AppCores.vermelho),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Uma única doação pode ajudar até quatro pessoas. Confira os '
                    'requisitos e prepare-se para doar com segurança.',
                  ),
                ),
              ],
            ),
          ),
          for (final t in _topicos) ...[
            TituloSecao(t.titulo),
            Cartao(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < t.itens.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Icon(t.icone, color: t.cor),
                        title: Text(t.itens[i].$1,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.itens[i].$2,
                              style: const TextStyle(height: 1.45)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Resumo das orientações do Ministério da Saúde '
            '(gov.br/saude — Doação de Sangue). A avaliação final é sempre feita '
            'pela triagem clínica do hemocentro, e os critérios podem mudar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppCores.textoSuave),
          ),
        ],
      ),
    );
  }
}
