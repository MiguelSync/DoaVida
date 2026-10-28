import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../utils/formatos.dart';
import '../../widgets/comuns.dart';
import '../faq_screen.dart';
import '../termos_screen.dart';
import 'editar_perfil_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  void _exportar(BuildContext context) {
    final json = context.read<AppState>().exportarDadosDoador();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Meus dados (LGPD)'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (context.mounted) {
                avisar(context, 'Dados copiados para a área de transferência.');
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluir(BuildContext context) async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir conta?',
      mensagem: 'Todos os seus dados pessoais, doações, agendamentos e '
          'notificações serão apagados definitivamente. Esta ação não pode '
          'ser desfeita.',
      botao: 'Excluir definitivamente',
      perigoso: true,
    );
    if (!ok || !context.mounted) return;
    await context.read<AppState>().excluirContaDoador();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final d = estado.doadorAtual!;

    Widget item(IconData icone, String rotulo, String valor) => ListTile(
          leading: Icon(icone, color: AppCores.vermelho),
          title: Text(rotulo,
              style: const TextStyle(fontSize: 12, color: AppCores.textoSuave)),
          subtitle: Text(valor,
              style: const TextStyle(
                  fontSize: 15,
                  color: AppCores.texto,
                  fontWeight: FontWeight.w600)),
          dense: true,
        );

    return PaginaLista(
      maxLargura: 720,
      children: [
        Cartao(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppCores.vermelho,
                child: Text(iniciais(d.nome),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.nome,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(d.email,
                        style: const TextStyle(color: AppCores.textoSuave)),
                  ],
                ),
              ),
              TipoBadge(d.tipo, tamanho: 52),
            ],
          ),
        ),
        TituloSecao(
          'Meus dados',
          acao: TextButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const EditarPerfilScreen(),
            )),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        ),
        Cartao(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              item(Icons.cake_outlined, 'Idade',
                  '${d.idade} anos (${fData(d.dataNascimento)})'),
              item(Icons.wc_outlined, 'Sexo biológico', d.sexo.label),
              item(Icons.monitor_weight_outlined, 'Peso',
                  '${d.peso.toStringAsFixed(d.peso % 1 == 0 ? 0 : 1)} kg'),
              item(Icons.phone_outlined, 'Telefone', d.telefone),
              item(Icons.location_on_outlined, 'Endereço',
                  '${d.endereco} — ${d.cidade}'),
            ],
          ),
        ),
        const TituloSecao('Notificações'),
        Cartao(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SwitchListTile(
            value: d.notificacoes,
            onChanged: (v) => estado.definirNotificacoes(v),
            secondary:
                const Icon(Icons.notifications_active_outlined, color: AppCores.vermelho),
            title: const Text('Alertas de campanhas e estoque crítico'),
            subtitle: Text(estado.pushDisponivel
                ? 'Você será avisado quando o tipo ${d.tipo.label} for necessário.'
                : 'Neste dispositivo os alertas aparecem na central de notificações do app.'),
          ),
        ),
        const TituloSecao('Privacidade e ajuda',
            subtitulo: 'Seus direitos como titular de dados (LGPD)'),
        Cartao(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Quem pode doar? (FAQ)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaqScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Termos de Uso e Privacidade'),
                subtitle: Text(
                    'Aceito em ${fData(d.termosAceitosEm)} · versão ${d.versaoTermos}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TermosScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Exportar meus dados'),
                subtitle: const Text('Veja tudo o que o app guarda sobre você'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _exportar(context),
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_forever_outlined, color: AppCores.critico),
                title: const Text('Excluir minha conta',
                    style: TextStyle(color: AppCores.critico)),
                subtitle: const Text('Apaga definitivamente todos os seus dados'),
                onTap: () => _excluir(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => context.read<AppState>().sair(),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          icon: const Icon(Icons.logout),
          label: const Text('Sair'),
        ),
      ],
    );
  }
}
