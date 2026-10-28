import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

  final storage = StorageService();
  await storage.init();

  final notificacoes = NotificationService();
  await notificacoes.init();

  final estado = AppState(storage, notificacoes);
  await estado.carregar();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: estado,
      child: const DoaVidaApp(),
    ),
  );
}
