import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../utils/formatos.dart';
import '../../widgets/comuns.dart';

/// Correção de dados pelo titular (LGPD art. 18, III).
/// Tipo sanguíneo, sexo e nascimento não são editáveis para evitar erros
/// no cálculo de compatibilidade — em caso de engano, o doador deve excluir
/// e refazer o cadastro ou procurar o hemocentro.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _peso;
  late final TextEditingController _telefone;
  late final TextEditingController _cidade;
  late final TextEditingController _endereco;

  @override
  void initState() {
    super.initState();
    final d = context.read<AppState>().doadorAtual!;
    _nome = TextEditingController(text: d.nome);
    _peso = TextEditingController(
        text: d.peso.toStringAsFixed(d.peso % 1 == 0 ? 0 : 1));
    _telefone = TextEditingController(text: d.telefone);
    _cidade = TextEditingController(text: d.cidade);
    _endereco = TextEditingController(text: d.endereco);
  }

  @override
  void dispose() {
    for (final c in [_nome, _peso, _telefone, _cidade, _endereco]) {
      c.dispose();
    }
    super.dispose();
  }

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    context.read<AppState>().atualizarDoador(
          nome: _nome.text,
          peso: double.parse(_peso.text.replaceAll(',', '.')),
          telefone: _telefone.text,
          cidade: _cidade.text,
          endereco: _endereco.text,
        );
    avisar(context, 'Dados atualizados.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<AppState>().doadorAtual;
    if (d == null) return const Scaffold();
    const espaco = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: const Text('Editar dados')),
      body: Form(
        key: _form,
        child: PaginaLista(
          maxLargura: 640,
          children: [
            Cartao(
              cor: AppCores.vermelho.withValues(alpha: 0.04),
              child: Row(children: [
                TipoBadge(d.tipo),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tipo sanguíneo, sexo e data de nascimento não podem ser '
                    'alterados por aqui (${d.sexo.label}, ${fData(d.dataNascimento)}).',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: campo('Nome completo', icone: Icons.person_outline),
              validator: (v) => (v == null || v.trim().split(' ').length < 2)
                  ? 'Informe nome e sobrenome'
                  : null,
            ),
            espaco,
            TextFormField(
              controller: _peso,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: campo('Peso',
                  icone: Icons.monitor_weight_outlined, sufixo: 'kg'),
              validator: (v) {
                final p = double.tryParse((v ?? '').replaceAll(',', '.'));
                return (p == null || p < 20 || p > 300)
                    ? 'Informe um peso válido'
                    : null;
              },
            ),
            espaco,
            TextFormField(
              controller: _telefone,
              keyboardType: TextInputType.phone,
              decoration: campo('Telefone', icone: Icons.phone_outlined),
              validator: (v) => apenasDigitos(v ?? '').length < 10
                  ? 'Informe um telefone com DDD'
                  : null,
            ),
            espaco,
            TextFormField(
              controller: _cidade,
              decoration: campo('Cidade', icone: Icons.location_city_outlined),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            espaco,
            TextFormField(
              controller: _endereco,
              decoration: campo('Endereço', icone: Icons.home_outlined),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _salvar,
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Salvar alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
