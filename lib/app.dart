import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/boas_vindas_screen.dart';
import 'screens/doador/doador_shell.dart';
import 'screens/instituicao/instituicao_shell.dart';
import 'state/app_state.dart';
import 'theme/tema.dart';

class DoaVidaApp extends StatelessWidget {
  const DoaVidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoaVida',
      debugShowCheckedModeBanner: false,
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

/// Decide a tela inicial conforme a sessão: boas-vindas, área do doador
/// ou painel da instituição.
class RaizApp extends StatelessWidget {
  const RaizApp({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final chave = ValueKey('${estado.papel}-${estado.usuarioId}');
    return switch (estado.papel) {
      null => BoasVindasScreen(key: chave),
      Papel.doador => DoadorShell(key: chave),
      Papel.instituicao => InstituicaoShell(key: chave),
    };
  }
}
