import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/seed_data.dart';
import '../state/app_state.dart';
import '../theme/tema.dart';
import '../widgets/comuns.dart';
import 'cadastro_doador_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.papel});
  final Papel papel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocultarSenha = true;
  String? _erro;

  bool get _doador => widget.papel == Papel.doador;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _entrar() {
    if (!_form.currentState!.validate()) return;
    final erro =
        context.read<AppState>().entrar(widget.papel, _email.text, _senha.text);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).popUntil((rota) => rota.isFirst);
  }

  List<(String, String)> get _contasDemo => _doador
      ? const [
          ('doador@demo.com', 'Lucas · O-'),
          ('mariana@demo.com', 'Mariana · A+'),
        ]
      : const [
          ('hemosc@demo.com', 'Hemosc Blumenau'),
          ('hrav@demo.com', 'Hosp. Regional Alto Vale'),
        ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_doador ? 'Entrar como doador' : 'Acesso institucional'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      _doador
                          ? Icons.volunteer_activism
                          : Icons.local_hospital_outlined,
                      size: 56,
                      color: AppCores.vermelho,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _doador
                          ? 'Bem-vindo(a) de volta!'
                          : 'Painel de hospitais e hemocentros',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: campo('E-mail', icone: Icons.mail_outline),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Informe um e-mail válido'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _senha,
                      obscureText: _ocultarSenha,
                      autofillHints: const [AutofillHints.password],
                      decoration:
                          campo('Senha', icone: Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          tooltip: _ocultarSenha ? 'Mostrar' : 'Ocultar',
                          icon: Icon(_ocultarSenha
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Informe a senha' : null,
                      onFieldSubmitted: (_) => _entrar(),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Text(_erro!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppCores.critico,
                              fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _entrar,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52)),
                      child: const Text('Entrar'),
                    ),
                    if (_doador) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CadastroDoadorScreen()),
                        ),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52)),
                        child: const Text('Quero me cadastrar como doador'),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Cartao(
                      cor: AppCores.vermelho.withValues(alpha: 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Contas de demonstração',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          const Text(
                            'Senha: ${SeedData.senhaDemo} · toque para preencher',
                            style: TextStyle(
                                fontSize: 12, color: AppCores.textoSuave),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (email, rotulo) in _contasDemo)
                                ActionChip(
                                  avatar: const Icon(Icons.person_outline,
                                      size: 18),
                                  label: Text(rotulo),
                                  onPressed: () => setState(() {
                                    _email.text = email;
                                    _senha.text = SeedData.senhaDemo;
                                    _erro = null;
                                  }),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
