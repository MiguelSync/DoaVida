import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/tema.dart';
import 'faq_screen.dart';
import 'login_screen.dart';

class BoasVindasScreen extends StatelessWidget {
  const BoasVindasScreen({super.key});

  void _abrirLogin(BuildContext context, Papel papel) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen(papel: papel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Logo(),
                  const SizedBox(height: 20),
                  Text(
                    'DoaVida',
                    textAlign: TextAlign.center,
                    style: texto.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppCores.vermelho,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conectando doadores de sangue aos hemocentros e hospitais '
                    'do Alto Vale do Itajaí.',
                    textAlign: TextAlign.center,
                    style:
                        texto.bodyLarge?.copyWith(color: AppCores.textoSuave),
                  ),
                  const SizedBox(height: 32),
                  _OpcaoEntrada(
                    icone: Icons.volunteer_activism,
                    titulo: 'Quero doar sangue',
                    texto: 'Cadastre-se, agende sua doação e receba alertas '
                        'quando o seu tipo sanguíneo for necessário.',
                    destaque: true,
                    onTap: () => _abrirLogin(context, Papel.doador),
                  ),
                  const SizedBox(height: 12),
                  _OpcaoEntrada(
                    icone: Icons.local_hospital_outlined,
                    titulo: 'Sou hospital ou hemocentro',
                    texto: 'Gerencie estoque e agendamentos e publique '
                        'alertas para doadores compatíveis.',
                    onTap: () => _abrirLogin(context, Papel.instituicao),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FaqScreen()),
                    ),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Quem pode doar? Tire suas dúvidas'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Projeto de Extensão · UNIDAVI\n'
                    'Pilar V — Universidade Solidária',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppCores.textoSuave),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE53935), AppCores.vermelhoEscuro],
          ),
          boxShadow: [
            BoxShadow(
              color: AppCores.vermelho.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.water_drop, color: Colors.white, size: 56),
      ),
    );
  }
}

class _OpcaoEntrada extends StatelessWidget {
  const _OpcaoEntrada({
    required this.icone,
    required this.titulo,
    required this.texto,
    required this.onTap,
    this.destaque = false,
  });

  final IconData icone;
  final String titulo;
  final String texto;
  final VoidCallback onTap;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final corTexto = destaque ? Colors.white : AppCores.texto;
    return Material(
      color: destaque ? AppCores.vermelho : Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: destaque ? null : Border.all(color: AppCores.borda),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: destaque
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppCores.vermelho.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icone,
                    color: destaque ? Colors.white : AppCores.vermelho),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: corTexto)),
                    const SizedBox(height: 4),
                    Text(texto,
                        style: TextStyle(
                            fontSize: 13,
                            color: corTexto.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: corTexto),
            ],
          ),
        ),
      ),
    );
  }
}
