import 'package:flutter/material.dart';

import '../theme/tema.dart';
import '../widgets/comuns.dart';

/// Termos de Uso e Política de Privacidade (RNF03 — LGPD).
/// Texto-modelo para fins acadêmicos.
class TermosScreen extends StatelessWidget {
  const TermosScreen({super.key});

  static const versao = '1.0';

  static const _secoes = <(String, String)>[
    (
      '1. Sobre o DoaVida',
      'O DoaVida é um aplicativo desenvolvido como Projeto de Extensão do curso '
          'de Sistemas de Informação da UNIDAVI, com o objetivo de conectar '
          'doadores de sangue a hemocentros e hospitais da região do Alto Vale '
          'do Itajaí. O uso do aplicativo é gratuito e voluntário.'
    ),
    (
      '2. Dados coletados',
      'Coletamos: nome, e-mail, senha (armazenada apenas de forma criptografada '
          'por hash), data de nascimento, sexo biológico, tipo sanguíneo, peso, '
          'telefone, cidade e endereço, além do histórico de doações e '
          'agendamentos. A localização do aparelho é usada somente no momento em '
          'que você abre o mapa e não é armazenada.'
    ),
    (
      '3. Dados sensíveis',
      'Tipo sanguíneo e informações de saúde são dados pessoais sensíveis '
          '(art. 5º, II, da LGPD). Eles são tratados com base no seu '
          'consentimento específico e destacado (art. 11, I), exclusivamente '
          'para as finalidades abaixo.'
    ),
    (
      '4. Finalidades',
      '• Calcular quando você estará apto(a) a doar novamente;\n'
          '• Permitir o agendamento de doações;\n'
          '• Avisar você quando hemocentros precisarem do seu tipo sanguíneo;\n'
          '• Gerar estatísticas agregadas e anônimas para as instituições.'
    ),
    (
      '5. Compartilhamento',
      'Os hemocentros e hospitais não têm acesso à sua lista completa de dados. '
          'Ao agendar uma doação, a instituição escolhida visualiza apenas seu '
          'nome reduzido, tipo sanguíneo, telefone e o horário marcado. Os '
          'alertas são enviados com base no tipo sanguíneo, sem expor a sua '
          'identidade à instituição. Não vendemos nem compartilhamos dados com '
          'terceiros.'
    ),
    (
      '6. Segurança',
      'As senhas são protegidas com hash criptográfico (SHA-256 com salt). '
          'O acesso às áreas do doador e da instituição é separado por perfil.'
    ),
    (
      '7. Seus direitos (art. 18 da LGPD)',
      'Você pode, a qualquer momento e direto pelo app: acessar e exportar seus '
          'dados, corrigir informações, desativar os alertas (revogar o '
          'consentimento de notificações) e excluir definitivamente sua conta e '
          'todos os dados associados.'
    ),
    (
      '8. Retenção',
      'Os dados são mantidos enquanto sua conta estiver ativa. Ao excluir a '
          'conta, todas as informações pessoais, doações, agendamentos e '
          'notificações vinculadas são removidas.'
    ),
    (
      '9. Responsabilidade',
      'O aplicativo não substitui a triagem clínica realizada pelo hemocentro. '
          'A decisão final sobre a aptidão para doar é sempre da equipe de saúde.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos e Privacidade')),
      body: PaginaLista(
        maxLargura: 720,
        children: [
          Cartao(
            cor: AppCores.vermelho.withValues(alpha: 0.04),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppCores.vermelho),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Termos de Uso e Política de Privacidade · versão $versao\n'
                    'Em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018).',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          for (final (titulo, texto) in _secoes) ...[
            const SizedBox(height: 18),
            Text(titulo,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 6),
            Text(texto, style: const TextStyle(height: 1.45)),
          ],
        ],
      ),
    );
  }
}
