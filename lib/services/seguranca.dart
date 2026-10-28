import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Proteção de credenciais (RNF02): a senha nunca é salva em texto puro.
/// Usa SHA-256 com salt aleatório por usuário e múltiplas iterações.
class Seguranca {
  static const _iteracoes = 1000;

  static String gerarSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hashSenha(String senha, String salt) {
    final saltBytes = utf8.encode(salt);
    var digest = sha256.convert(utf8.encode('$salt:$senha'));
    for (var i = 0; i < _iteracoes; i++) {
      digest = sha256.convert([...digest.bytes, ...saltBytes]);
    }
    return digest.toString();
  }

  static bool conferir(String senha, String salt, String hashEsperado) =>
      hashSenha(senha, salt) == hashEsperado;
}
