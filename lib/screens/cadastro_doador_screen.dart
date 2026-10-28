import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/doador.dart';
import '../models/tipo_sanguineo.dart';
import '../state/app_state.dart';
import '../theme/tema.dart';
import '../utils/formatos.dart';
import '../widgets/comuns.dart';
import 'termos_screen.dart';

/// RF01 — Cadastro de doador. RNF03 — aceite explícito dos termos (LGPD).
class CadastroDoadorScreen extends StatefulWidget {
  const CadastroDoadorScreen({super.key});

  @override
  State<CadastroDoadorScreen> createState() => _CadastroDoadorScreenState();
}

class _CadastroDoadorScreenState extends State<CadastroDoadorScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmaSenha = TextEditingController();
  final _nascimentoTexto = TextEditingController();
  final _peso = TextEditingController();
  final _telefone = TextEditingController();
  final _cidade = TextEditingController(text: 'Rio do Sul');
  final _endereco = TextEditingController();

  DateTime? _nascimento;
  Sexo? _sexo;
  TipoSanguineo? _tipo;
  bool _aceite = false;
  bool _notificacoes = true;
  bool _tentouEnviar = false;
  bool _ocultarSenha = true;

  @override
  void dispose() {
    for (final c in [
      _nome,
      _email,
      _senha,
      _confirmaSenha,
      _nascimentoTexto,
      _peso,
      _telefone,
      _cidade,
      _endereco,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _escolherNascimento() async {
    final hoje = DateTime.now();
    final r = await showDatePicker(
      context: context,
      initialDate: _nascimento ?? DateTime(hoje.year - 25, 1, 1),
      firstDate: DateTime(hoje.year - 100),
      lastDate: hoje,
      helpText: 'Data de nascimento',
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (r == null) return;
    setState(() {
      _nascimento = r;
      _nascimentoTexto.text = fData(r);
    });
  }

  void _enviar() {
    setState(() => _tentouEnviar = true);
    final formOk = _form.currentState!.validate();
    if (!formOk || _sexo == null || _tipo == null) {
      avisar(context, 'Confira os campos destacados.');
      return;
    }
    if (!_aceite) {
      avisar(context, 'Para continuar, aceite os Termos de Uso e a Política de Privacidade.');
      return;
    }
    final erro = context.read<AppState>().cadastrarDoador(
          nome: _nome.text,
          email: _email.text,
          senha: _senha.text,
          nascimento: _nascimento!,
          sexo: _sexo!,
          tipo: _tipo!,
          peso: double.parse(_peso.text.replaceAll(',', '.')),
          telefone: _telefone.text,
          cidade: _cidade.text,
          endereco: _endereco.text,
          aceitouTermos: _aceite,
          notificacoes: _notificacoes,
        );
    if (erro != null) {
      avisar(context, erro);
      return;
    }
    Navigator.of(context).popUntil((rota) => rota.isFirst);
  }

  String? _obrigatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

  @override
  Widget build(BuildContext context) {
    const espaco = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de doador')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: PaginaLista(
            maxLargura: 640,
            children: [
              const TituloSecao('Dados de acesso'),
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
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: campo('E-mail', icone: Icons.mail_outline),
                validator: (v) {
                  final e = v?.trim() ?? '';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
                    return 'Informe um e-mail válido';
                  }
                  return null;
                },
              ),
              espaco,
              TextFormField(
                controller: _senha,
                obscureText: _ocultarSenha,
                decoration: campo('Senha', icone: Icons.lock_outline,
                        ajuda: 'Mínimo de 6 caracteres')
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarSenha
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _ocultarSenha = !_ocultarSenha),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'A senha precisa ter pelo menos 6 caracteres'
                    : null,
              ),
              espaco,
              TextFormField(
                controller: _confirmaSenha,
                obscureText: _ocultarSenha,
                decoration: campo('Confirmar senha', icone: Icons.lock_outline),
                validator: (v) =>
                    v != _senha.text ? 'As senhas não conferem' : null,
              ),
              const TituloSecao('Dados de saúde',
                  subtitulo:
                      'Usados para calcular sua aptidão e avisar quando seu tipo for necessário.'),
              TextFormField(
                controller: _nascimentoTexto,
                readOnly: true,
                onTap: _escolherNascimento,
                decoration: campo('Data de nascimento',
                    icone: Icons.cake_outlined, dica: 'dd/mm/aaaa'),
                validator: (_) =>
                    _nascimento == null ? 'Informe a data de nascimento' : null,
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
                  if (p == null || p < 20 || p > 300) {
                    return 'Informe um peso válido';
                  }
                  return null;
                },
              ),
              espaco,
              const Text('Sexo biológico',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Text(
                'Define o intervalo entre doações (60 dias para homens, 90 para mulheres).',
                style: TextStyle(fontSize: 12, color: AppCores.textoSuave),
              ),
              const SizedBox(height: 8),
              SegmentedButton<Sexo>(
                emptySelectionAllowed: true,
                segments: [
                  for (final s in Sexo.values)
                    ButtonSegment(value: s, label: Text(s.label)),
                ],
                selected: _sexo == null ? <Sexo>{} : {_sexo!},
                onSelectionChanged: (sel) =>
                    setState(() => _sexo = sel.isEmpty ? null : sel.first),
              ),
              if (_tentouEnviar && _sexo == null) const _ErroCampo('Selecione uma opção'),
              const SizedBox(height: 16),
              const Text('Tipo sanguíneo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Text(
                'Consulte sua carteirinha de doador ou um exame de tipagem.',
                style: TextStyle(fontSize: 12, color: AppCores.textoSuave),
              ),
              const SizedBox(height: 8),
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      selected: _tipo == t,
                      onSelected: (_) => setState(() => _tipo = t),
                    ),
                ],
              ),
              if (_tentouEnviar && _tipo == null)
                const _ErroCampo('Selecione seu tipo sanguíneo'),
              const TituloSecao('Contato e endereço'),
              TextFormField(
                controller: _telefone,
                keyboardType: TextInputType.phone,
                decoration: campo('Telefone / WhatsApp',
                    icone: Icons.phone_outlined, dica: '(47) 99999-9999'),
                validator: (v) => apenasDigitos(v ?? '').length < 10
                    ? 'Informe um telefone com DDD'
                    : null,
              ),
              espaco,
              TextFormField(
                controller: _cidade,
                textCapitalization: TextCapitalization.words,
                decoration:
                    campo('Cidade', icone: Icons.location_city_outlined),
                validator: _obrigatorio,
              ),
              espaco,
              TextFormField(
                controller: _endereco,
                textCapitalization: TextCapitalization.sentences,
                decoration: campo('Endereço', icone: Icons.home_outlined,
                    dica: 'Rua, número, bairro'),
                validator: _obrigatorio,
              ),
              const TituloSecao('Privacidade'),
              Cartao(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      value: _notificacoes,
                      onChanged: (v) => setState(() => _notificacoes = v),
                      title: const Text('Receber alertas de doação'),
                      subtitle: const Text(
                          'Avisos quando hemocentros precisarem do seu tipo sanguíneo.'),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      value: _aceite,
                      onChanged: (v) => setState(() => _aceite = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Li e aceito os Termos de Uso e a Política de Privacidade, '
                        'e autorizo o tratamento dos meus dados — inclusive dados '
                        'de saúde, como o tipo sanguíneo — para as finalidades '
                        'descritas, conforme a LGPD (Lei nº 13.709/2018).',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const TermosScreen()),
                        ),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Ler os termos completos'),
                      ),
                    ),
                    if (_tentouEnviar && !_aceite)
                      const Padding(
                        padding: EdgeInsets.only(left: 16, bottom: 8),
                        child: _ErroCampo('O aceite é obrigatório'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _aceite ? _enviar : null,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: const Text('Criar minha conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErroCampo extends StatelessWidget {
  const _ErroCampo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(texto,
          style: const TextStyle(color: AppCores.critico, fontSize: 12)),
    );
  }
}
