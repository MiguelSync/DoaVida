import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'models/notificacao.dart';
import 'screens/boas_vindas_screen.dart';
import 'screens/doador/doador_shell.dart';
import 'screens/instituicao/instituicao_shell.dart';
import 'state/app_state.dart';
import 'theme/tema.dart';

class DoaVidaApp extends StatefulWidget {
  const DoaVidaApp({super.key});

  @override
  State<DoaVidaApp> createState() => _DoaVidaAppState();
}

class _DoaVidaAppState extends State<DoaVidaApp> {
  final _mensageiro = GlobalKey<ScaffoldMessengerState>();
  final List<StreamSubscription<Object>> _assinaturas = [];

  @override
  void initState() {
    super.initState();
    final estado = context.read<AppState>();
    _assinaturas
      ..add(estado.mensagens.listen(_avisar))
      ..add(estado.novasNotificacoes.listen(_novaNotificacao));
  }

  @override
  void dispose() {
    for (final a in _assinaturas) {
      a.cancel();
    }
    super.dispose();
  }

  void _avisar(String texto) {
    _mensageiro.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Alerta que chegou em tempo real (publicado por um hospital/hemocentro).
  void _novaNotificacao(Notificacao n) {
    _mensageiro.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: AppCores.vermelho,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(n.corpo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoaVida',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _mensageiro,
      theme: AppTema.claro,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RaizApp(),
    );
  }
}

/// Decide a tela inicial conforme a sessão: abertura (carregando),
/// boas-vindas, área do doador ou painel da instituição.
class RaizApp extends StatelessWidget {
  const RaizApp({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    if (estado.carregando) return const _Abertura();
    final chave = ValueKey('${estado.papel}-${estado.usuarioId}');
    return switch (estado.papel) {
      null => BoasVindasScreen(key: chave),
      Papel.doador => DoadorShell(key: chave),
      Papel.instituicao => InstituicaoShell(key: chave),
    };
  }
}

class _Abertura extends StatelessWidget {
  const _Abertura();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bloodtype, size: 64, color: AppCores.vermelho),
            SizedBox(height: 16),
            Text('DoaVida',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
