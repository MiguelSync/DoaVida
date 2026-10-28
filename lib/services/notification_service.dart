import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificações do sistema (RF07).
///
/// No protótipo, quando o hospital publica um alerta, a notificação é
/// disparada localmente no aparelho (simulando o push). Para push real entre
/// aparelhos diferentes, basta trocar a implementação de [mostrar] por
/// Firebase Cloud Messaging — o resto do app não muda.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _pronto = false;
  int _proximoId = 1;

  bool get disponivel => _pronto;

  Future<void> init() async {
    if (kIsWeb) return; // Web: o app usa só a caixa de entrada interna.
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      );
      await _plugin.initialize(settings);
      _pronto = true;
    } catch (e) {
      debugPrint('Notificações indisponíveis: $e');
    }
  }

  Future<void> pedirPermissao() async {
    if (!_pronto) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Falha ao pedir permissão de notificação: $e');
    }
  }

  Future<bool> mostrar(String titulo, String corpo) async {
    if (!_pronto) return false;
    try {
      const detalhes = NotificationDetails(
        android: AndroidNotificationDetails(
          'alertas_doacao',
          'Alertas de doação',
          channelDescription:
              'Campanhas e alertas de estoque crítico dos hemocentros',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );
      await _plugin.show(_proximoId++, titulo, corpo, detalhes);
      return true;
    } catch (e) {
      debugPrint('Falha ao mostrar notificação: $e');
      return false;
    }
  }
}
