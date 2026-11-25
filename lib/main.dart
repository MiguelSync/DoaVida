import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

  // Backend em nuvem: Firebase Authentication + Cloud Firestore.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notificacoes = NotificationService();
  await notificacoes.init();

  final estado = AppState(FirebaseService(), notificacoes);
  // Restaura a sessão em segundo plano; enquanto isso o app mostra a abertura.
  estado.carregar();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: estado,
      child: const DoaVidaApp(),
    ),
  );
}
