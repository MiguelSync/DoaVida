import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local do protótipo (substituível por Firebase/API depois).
/// Todo o "banco" é serializado em JSON numa única chave.
class StorageService {
  static const _chaveBanco = 'doavida_banco_v1';
  static const _chaveSessao = 'doavida_sessao_v1';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Map<String, dynamic>? lerBanco() {
    final texto = _prefs.getString(_chaveBanco);
    if (texto == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(texto) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarBanco(Map<String, dynamic> banco) =>
      _prefs.setString(_chaveBanco, jsonEncode(banco));

  /// Retorna (papel, id) da sessão salva.
  (String, String)? lerSessao() {
    final s = _prefs.getString(_chaveSessao);
    if (s == null || !s.contains('|')) return null;
    final partes = s.split('|');
    return (partes[0], partes[1]);
  }

  Future<void> salvarSessao(String papel, String id) =>
      _prefs.setString(_chaveSessao, '$papel|$id');

  Future<void> limparSessao() => _prefs.remove(_chaveSessao);
}
